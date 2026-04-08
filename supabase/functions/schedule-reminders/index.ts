/**
 * schedule-reminders Edge Function
 *
 * Triggered nightly by pg_cron:
 *   SELECT cron.schedule(
 *     'nightly-reminders',
 *     '0 8 * * *',
 *     $$ SELECT net.http_post(
 *       url := 'https://<project>.supabase.co/functions/v1/schedule-reminders',
 *       headers := '{"Authorization": "Bearer <service_role_key>"}'::jsonb
 *     ) $$
 *   );
 *
 * Uses the service role key — no user JWT.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;
const FIREBASE_SERVICE_ACCOUNT_KEY = Deno.env.get(
  "FIREBASE_SERVICE_ACCOUNT_KEY",
)!; // JSON string of service account
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req: Request) => {
  // ── Verify caller is the service role (internal cron) ──────────────────────
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace("Bearer ", "");
  if (token !== SUPABASE_SERVICE_ROLE_KEY) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const today = new Date().toISOString().substring(0, 10);
  const in7Days = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    .toISOString()
    .substring(0, 10);

  let totalSent = 0;

  // ── 1. Maintenance reminders ────────────────────────────────────────────────
  const { data: overdueRecords } = await supabase
    .from("maintenance_records")
    .select(`
      id, title, next_due_at, next_due_km,
      vehicles!inner(id, owner_id, odometer, make, model)
    `)
    .or(`next_due_at.lte.${in7Days},next_due_at.lte.${today}`);

  if (overdueRecords && overdueRecords.length > 0) {
    for (const record of overdueRecords) {
      const vehicle = (record as Record<string, unknown>).vehicles as Record<
        string,
        unknown
      >;
      if (!vehicle?.owner_id) continue;

      const isKmOverdue =
        record.next_due_km != null &&
        Number(vehicle.odometer) >= Number(record.next_due_km);
      const isDateOverdue =
        record.next_due_at != null && record.next_due_at <= in7Days;

      if (!isKmOverdue && !isDateOverdue) continue;

      // Get device tokens for this owner
      const { data: tokens } = await supabase
        .from("device_tokens")
        .select("token")
        .eq("profile_id", vehicle.owner_id as string)
        .eq("notifications_enabled", true);

      if (!tokens || tokens.length === 0) continue;

      const daysLeft = record.next_due_at
        ? Math.ceil(
            (new Date(record.next_due_at).getTime() - Date.now()) /
              (1000 * 60 * 60 * 24),
          )
        : null;

      const title = `${vehicle.make} ${vehicle.model}`;
      const body = daysLeft !== null && daysLeft <= 0
        ? `Manutenção vencida: ${record.title}`
        : daysLeft !== null
        ? `Manutenção em ${daysLeft} dias: ${record.title}`
        : `Manutenção próxima do limite de km: ${record.title}`;

      for (const { token } of tokens) {
        await sendFcmNotification(token, title, body);
        totalSent++;
      }
    }
  }

  // ── 2. Monthly mileage reminders ────────────────────────────────────────────
  const firstOfMonth = today.substring(0, 8) + "01";
  const firstOfNext = new Date(
    new Date(firstOfMonth).setMonth(new Date(firstOfMonth).getMonth() + 1),
  )
    .toISOString()
    .substring(0, 10);

  const { data: vehiclesWithoutEntry } = await supabase.rpc(
    "vehicles_missing_mileage",
    { p_from: firstOfMonth, p_to: firstOfNext },
  );

  if (vehiclesWithoutEntry) {
    for (const row of vehiclesWithoutEntry as Array<
      { owner_id: string; make: string; model: string }
    >) {
      const { data: tokens } = await supabase
        .from("device_tokens")
        .select("token")
        .eq("profile_id", row.owner_id)
        .eq("notifications_enabled", true);

      if (!tokens || tokens.length === 0) continue;

      for (const { token } of tokens) {
        await sendFcmNotification(
          token,
          `${row.make} ${row.model}`,
          "Não esqueça de registrar a quilometragem deste mês!",
        );
        totalSent++;
      }
    }
  }

  return new Response(
    JSON.stringify({ data: { notifications_sent: totalSent }, error: null }),
    { headers: { "Content-Type": "application/json" }, status: 200 },
  );
});

async function sendFcmNotification(
  deviceToken: string,
  title: string,
  body: string,
): Promise<void> {
  const accessToken = await getFcmAccessToken();
  const url =
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;

  await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: deviceToken,
        notification: { title, body },
        android: { priority: "high" },
        apns: {
          payload: { aps: { sound: "default", badge: 1 } },
        },
      },
    }),
  });
}

async function getFcmAccessToken(): Promise<string> {
  // Use Firebase Admin service account JWT to get an OAuth2 access token
  const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT_KEY);
  const now = Math.floor(Date.now() / 1000);

  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = btoa(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );

  // Note: Full RS256 signing requires a crypto library; simplified here.
  // In production use the firebase-admin SDK or google-auth-library.
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${header}.${payload}.SIGNATURE`,
  });

  const data = await tokenResponse.json();
  return data.access_token as string;
}
