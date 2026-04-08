import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import OpenAI from "https://esm.sh/openai@4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  // ── 1. Verify JWT ──────────────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonError("Unauthorized", 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceKey);

  const token = authHeader.replace("Bearer ", "");
  const { data: { user }, error: authError } = await supabase.auth.getUser(
    token,
  );
  if (authError || !user) {
    return jsonError("Unauthorized", 401);
  }

  // ── 2. Parse request body ──────────────────────────────────────────────────
  let invoiceId: string;
  try {
    const body = await req.json();
    invoiceId = body.invoice_id;
    if (!invoiceId) throw new Error("Missing invoice_id");
  } catch {
    return jsonError("Bad Request: invoice_id required", 400);
  }

  // ── 3. Fetch invoice row ───────────────────────────────────────────────────
  const { data: invoice, error: fetchError } = await supabase
    .from("invoices")
    .select("id, photo_url, vehicle_id")
    .eq("id", invoiceId)
    .single();

  if (fetchError || !invoice) {
    return jsonError("Invoice not found", 404);
  }

  // Confirm the invoice belongs to the authenticated user (via RLS on vehicles)
  const { data: vehicle } = await supabase
    .from("vehicles")
    .select("owner_id")
    .eq("id", invoice.vehicle_id)
    .single();

  if (!vehicle || vehicle.owner_id !== user.id) {
    return jsonError("Forbidden", 403);
  }

  // ── 4. Generate a short-lived signed URL for the image ────────────────────
  const { data: signedData, error: signedError } = await supabase.storage
    .from("invoices")
    .createSignedUrl(invoice.photo_url, 300); // 5 min expiry

  if (signedError || !signedData?.signedUrl) {
    return jsonError("Failed to generate signed URL", 500);
  }

  // ── 5. Call OpenAI GPT-4o Vision ──────────────────────────────────────────
  const openai = new OpenAI({
    apiKey: Deno.env.get("OPENAI_API_KEY")!,
  });

  let rawText = "";
  let parsedItems: Array<{
    description: string;
    quantity: number;
    unit_price: number;
    item_type: string;
  }> = [];

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o",
      max_tokens: 1500,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text:
                `Você é um extrator de dados de notas fiscais brasileiras (NF-e / cupom fiscal).
Analise a imagem e retorne SOMENTE um JSON válido no seguinte formato, sem qualquer texto adicional:
{
  "items": [
    {
      "description": "nome do item",
      "quantity": 1,
      "unit_price": 0.00,
      "item_type": "part" | "labor" | "other"
    }
  ],
  "total_brl": 0.00,
  "issued_at": "YYYY-MM-DD"
}

Regras:
- item_type = "part" para peças e produtos
- item_type = "labor" para serviços e mão de obra
- item_type = "other" para demais itens
- Preços em formato numérico (ex: 150.00, não "R$ 150,00")
- Se não conseguir extrair um campo, use null`,
            },
            {
              type: "image_url",
              image_url: { url: signedData.signedUrl, detail: "high" },
            },
          ],
        },
      ],
    });

    const content = completion.choices[0].message.content ?? "";
    rawText = content;

    // Extract JSON from the response
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      parsedItems = (parsed.items ?? []).map((item: Record<string, unknown>) => ({
        description: String(item.description ?? "Item sem descrição"),
        quantity: Number(item.quantity ?? 1),
        unit_price: Number(item.unit_price ?? 0),
        item_type: ["part", "labor", "other"].includes(
            String(item.item_type),
          )
          ? String(item.item_type)
          : "other",
      }));

      // ── 6. Insert invoice_items ──────────────────────────────────────────
      if (parsedItems.length > 0) {
        const rows = parsedItems.map((item) => ({
          invoice_id: invoiceId,
          ...item,
        }));
        await supabase.from("invoice_items").insert(rows);
      }

      // ── 7. Update invoices row ───────────────────────────────────────────
      const updatePayload: Record<string, unknown> = {
        ai_parsed_at: new Date().toISOString(),
        // Never expose raw_text to client; store server-side only
      };
      if (parsed.total_brl != null) {
        updatePayload.total_brl = Number(parsed.total_brl);
      }
      if (parsed.issued_at) {
        updatePayload.issued_at = String(parsed.issued_at);
      }
      await supabase.from("invoices").update(updatePayload).eq("id", invoiceId);
    }
  } catch (aiError) {
    console.error("AI parsing error:", aiError);
    // Mark as parsed even on error so the UI doesn't spin forever
    await supabase
      .from("invoices")
      .update({ ai_parsed_at: new Date().toISOString() })
      .eq("id", invoiceId);
    return jsonError("AI parsing failed", 500);
  }

  // ── 8. Return structured result (never raw AI response) ───────────────────
  return new Response(
    JSON.stringify({ data: { items: parsedItems }, error: null }),
    {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    },
  );
});

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ data: null, error: message }), {
    headers: { "Content-Type": "application/json" },
    status,
  });
}
