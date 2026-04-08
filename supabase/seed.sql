-- Seed data: maintenance_templates
-- Common Brazilian vehicle maintenance intervals.
-- make = NULL means applies to all makes; model = NULL means all models.

INSERT INTO maintenance_templates (make, model, title, interval_months, interval_km, notes) VALUES
-- Universal templates (all makes/models)
(NULL, NULL, 'Troca de óleo e filtro',           6,  10000, 'Usar óleo especificado no manual do veículo'),
(NULL, NULL, 'Revisão dos freios',               12, 20000, 'Verificar pastilhas, discos e fluido de freio'),
(NULL, NULL, 'Alinhamento e balanceamento',      12, 15000, NULL),
(NULL, NULL, 'Rodízio de pneus',                  6, 10000, NULL),
(NULL, NULL, 'Troca do filtro de ar',             12, 15000, NULL),
(NULL, NULL, 'Troca do filtro de combustível',    12, 20000, NULL),
(NULL, NULL, 'Verificação da bateria',            12,  NULL, 'Bateria média dura 2-4 anos'),
(NULL, NULL, 'Troca do fluido de arrefecimento',  24, 40000, NULL),
(NULL, NULL, 'Troca do fluido de freio',          24,  NULL, 'Fluido DOT 3 ou DOT 4 conforme manual'),
(NULL, NULL, 'Troca das velas de ignição',        24, 40000, 'Velas de platina/irídio durem mais'),
(NULL, NULL, 'Verificação da correia dentada',    24, 40000, 'Trocar se houver desgaste ou ruído'),
(NULL, NULL, 'Troca da correia dentada',          48, 80000, 'Preventivo; pode variar por modelo'),
(NULL, NULL, 'Troca do líquido de direção',       24, 40000, 'Para veículos com direção hidráulica'),
(NULL, NULL, 'Revisão do ar-condicionado',        12,  NULL, 'Verificar gás, filtro e correia'),
(NULL, NULL, 'Recarga de gás do ar-condicionado', 24,  NULL, NULL),
(NULL, NULL, 'Troca do filtro de cabine',         12, 15000, NULL),
(NULL, NULL, 'Verificação de amortecedores',      24, 40000, NULL),
(NULL, NULL, 'Revisão geral',                     12, 20000, 'Incluir todos os itens de segurança'),

-- Volkswagen — específicos
('Volkswagen', NULL, 'Troca do óleo cambio (automático)',  48, 60000, 'Usar ATF específico da VW'),
('Volkswagen', NULL, 'Inspeção do sistema DSG/câmbio',    24, 40000, 'Verificar fluido e embreagem'),

-- Chevrolet — específicos
('Chevrolet', NULL, 'Troca do filtro de transmissão',     48, 60000, NULL),

-- Fiat — específicos
('Fiat', NULL, 'Verificação do câmbio Dualogic',          24, 30000, 'Calibração e troca de fluido'),

-- Toyota — específicos
('Toyota', NULL, 'Inspeção do CVT',                       36, 60000, 'Fluido de CVT Toyota original'),
('Toyota', NULL, 'Troca do fluido CVT',                   48, 80000, NULL),

-- Honda — específicos
('Honda', NULL, 'Inspeção VTEC',                          24, 40000, 'Verificar atuador e solenoide'),
('Honda', NULL, 'Troca do fluido câmbio CVT',             48, 60000, 'Honda HCF-2 obrigatório'),

-- Ford — específicos
('Ford', NULL, 'Inspeção PowerShift',                     24, 40000, 'Histórico de recalls; verificar software'),

-- Hyundai / Kia
('Hyundai', NULL, 'Troca do óleo câmbio automático',      48, 60000, NULL),
('Kia',     NULL, 'Troca do óleo câmbio automático',      48, 60000, NULL),

-- Renault
('Renault', NULL, 'Revisão câmbio EDC/automatizado',      24, 40000, NULL),

-- Jeep / Chrysler
('Jeep', NULL, 'Troca do fluido da caixa de transferência', 48, 60000, NULL),
('Jeep', NULL, 'Revisão do 4x4',                             24, 40000, NULL);
