-- =====================================================================
-- Analyse de cohortes et de rétention client
-- Données : bigquery-public-data.thelook_ecommerce (BigQuery, jeu public)
-- Outil : Google BigQuery (SQL standard)
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Exploration : répartition des commandes par statut
--    Objectif : repérer les commandes à exclure (annulées, retournées)
-- ---------------------------------------------------------------------
SELECT
  status,
  COUNT(*) AS nb_commandes
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY status
ORDER BY nb_commandes DESC;


-- ---------------------------------------------------------------------
-- 2. Contrôle des dates : période couverte par les données
--    Résultat : du 26/01/2019 au jour de l'extraction (09/11/2026).
--    Le mois en cours est incomplet : l'analyse s'arrête au 31/10/2026.
-- ---------------------------------------------------------------------
SELECT
  MIN(created_at) AS premiere_commande,
  MAX(created_at) AS derniere_commande
FROM `bigquery-public-data.thelook_ecommerce.orders`;


-- ---------------------------------------------------------------------
-- 3. Taille des cohortes : nombre de nouveaux clients par mois
--    La cohorte d'un client = le mois de son premier achat valide.
-- ---------------------------------------------------------------------
WITH premiers_achats AS (
  SELECT
    user_id,
    DATE_TRUNC(DATE(MIN(created_at)), MONTH) AS mois_cohorte
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status NOT IN ('Cancelled', 'Returned')
  GROUP BY user_id
)
SELECT
  mois_cohorte,
  COUNT(*) AS nb_clients
FROM premiers_achats
GROUP BY mois_cohorte
ORDER BY mois_cohorte;


-- ---------------------------------------------------------------------
-- 4. Tableau de rétention par cohorte (requête finale)
--    Pour chaque cohorte (nov. 2025 à oct. 2026) et chaque mois écoulé
--    depuis le premier achat : nombre de clients actifs et % de rétention.
--    Résultat exporté vers Google Sheets puis Looker Studio.
-- ---------------------------------------------------------------------
WITH commandes AS (
  -- Commandes valides, ramenées à leur mois, avant le mois incomplet
  SELECT
    user_id,
    DATE_TRUNC(DATE(created_at), MONTH) AS mois_commande
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status NOT IN ('Cancelled', 'Returned')
    AND DATE(created_at) < DATE '2026-11-01'
),
cohortes AS (
  -- Mois du premier achat de chaque client
  SELECT user_id, MIN(mois_commande) AS mois_cohorte
  FROM commandes
  GROUP BY user_id
),
activite AS (
  -- Un client compté une seule fois par mois d'activité
  SELECT DISTINCT
    c.user_id,
    co.mois_cohorte,
    DATE_DIFF(c.mois_commande, co.mois_cohorte, MONTH) AS mois_ecoules
  FROM commandes c
  JOIN cohortes co USING (user_id)
),
comptage AS (
  SELECT
    mois_cohorte,
    mois_ecoules,
    COUNT(*) AS clients_actifs
  FROM activite
  WHERE mois_cohorte >= DATE '2025-11-01'
  GROUP BY mois_cohorte, mois_ecoules
)
SELECT
  mois_cohorte,
  mois_ecoules,
  clients_actifs,
  -- Fonction de fenêtre : taille de la cohorte = clients actifs au mois 0
  FIRST_VALUE(clients_actifs) OVER (
    PARTITION BY mois_cohorte ORDER BY mois_ecoules
  ) AS taille_cohorte,
  ROUND(100 * clients_actifs / FIRST_VALUE(clients_actifs) OVER (
    PARTITION BY mois_cohorte ORDER BY mois_ecoules
  ), 1) AS retention_pct
FROM comptage
ORDER BY mois_cohorte, mois_ecoules;

-- Contrôle de cohérence : 12 cohortes observées sur 12, 11, ..., 1 mois
-- => 12 + 11 + ... + 1 = 78 lignes attendues, 78 lignes obtenues.
