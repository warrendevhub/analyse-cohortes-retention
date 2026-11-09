# Analyse de cohortes et de rétention client – E-commerce

Analyse en SQL (BigQuery) de la rétention des clients d'une boutique en ligne : quelle part des nouveaux clients revient acheter les mois suivants ?

**Résultat principal : la rétention à 1 mois est passée d'environ 3 % pour les cohortes de fin 2025 à 11,1 % pour la cohorte de septembre 2026.**

## Liens

- 📊 [Tableau de bord interactif (Looker Studio)](https://datastudio.google.com/reporting/3f03bee6-3125-441f-b0f1-2ff7bc95a46b)
- 🧾 [Requêtes SQL commentées](analyse_cohortes.sql)

## Contexte

Une **cohorte** regroupe les clients selon le mois de leur premier achat. Pour chaque cohorte, on mesure le pourcentage de clients qui achètent à nouveau 1, 2, 3… mois plus tard. C'est l'indicateur de **rétention**, suivi par les équipes marketing et CRM pour mesurer la fidélité.

## Données

Jeu de données public **thelook_ecommerce** de Google BigQuery : une boutique de vêtements fictive (clients, commandes, produits), mise à jour en continu. Commandes de janvier 2019 à novembre 2026.

## Démarche

1. **Exploration** : répartition des commandes par statut ; les commandes annulées et retournées sont exclues.
2. **Contrôle des dates** : le mois de novembre 2026 étant en cours, l'analyse s'arrête au **31 octobre 2026** pour ne garder que des mois complets.
3. **Taille des cohortes** : le nombre de nouveaux clients passe de 2 en janvier 2019 à environ 2 800 en octobre 2026.
4. **Calcul de la rétention en SQL** sur les 12 dernières cohortes (novembre 2025 à octobre 2026) : CTE, jointure, `DATE_DIFF`, `DISTINCT`, et fonction de fenêtre `FIRST_VALUE() OVER (PARTITION BY ...)` pour obtenir la taille de chaque cohorte.
5. **Contrôle de cohérence** : 78 lignes attendues (12 + 11 + … + 1), 78 obtenues.
6. **Restitution** : export vers Google Sheets, puis carte de chaleur dans Looker Studio.

## Résultats

| Cohorte (mois du 1er achat) | Rétention à 1 mois |
|---|---|
| Novembre 2025 | 3,1 % |
| Décembre 2025 | 2,7 % |
| Janvier 2026 | 2,7 % |
| Mars 2026 | 4,0 % |
| Juin 2026 | 5,3 % |
| Juillet 2026 | 6,9 % |
| Août 2026 | 8,4 % |
| Septembre 2026 | 11,1 % |

- **Une rétention faible mais stable** : pour les cohortes les plus anciennes, environ 3 % des clients rachètent chaque mois, et ce niveau reste stable jusqu'à 11 mois après le premier achat. La grande majorité des clients n'achète qu'une fois, mais un petit noyau fidèle revient régulièrement.
- **Une forte amélioration sur les cohortes récentes** : la rétention à 1 mois a été multipliée par 3 à 4 entre les cohortes de fin 2025 et celle de septembre 2026.

## Recommandations

- **Agir dès le premier mois** : la plupart des clients qui ne reviennent pas sont perdus dès le mois 1. Une séquence d'emails après le premier achat (remerciement, recommandations, offre sur la 2e commande) cible ce moment clé.
- **Identifier ce qui a changé récemment** : comprendre ce qui explique la hausse de la rétention des cohortes de 2026 (canal d'acquisition, offre, produit) pour le généraliser.
- **Suivre la rétention à 1 mois comme indicateur clé**, cohorte par cohorte.

## Limites

- Les données sont **fictives** et générées automatiquement : la hausse récente peut refléter le fonctionnement du générateur plutôt qu'un comportement réel.
- Les cohortes récentes ont peu de mois d'historique : leur rétention à long terme reste à confirmer.
- Un client est compté actif s'il a passé au moins une commande valide dans le mois, quel que soit le montant.

## Outils

SQL (Google BigQuery) · Google Sheets · Looker Studio
