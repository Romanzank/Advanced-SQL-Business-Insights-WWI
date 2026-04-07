# Wide World Importers (WWI) - Advanced SQL Business Analysis

## Project Overview
This project involves an in-depth Business Intelligence analysis of the **Wide World Importers (WWI)** dataset. The goal was to solve 10 complex business challenges using advanced SQL techniques, providing insights into sales, customer behavior, and inventory management.

---

## Key Business Questions Solved
* **Growth Metrics (Q1):** Calculating Year-over-Year (YoY) growth and linear income projections.
* **Churn Analysis (Q9):** Identifying "Potential Churn" customers based on their order frequency patterns.
* **Top Performers (Q2, Q6):** Ranking top customers by revenue and geographical distribution.
* **Inventory & Profit (Q3, Q4):** Identifying high-margin products and top-selling stock items.
* **Market Distribution (Q10):** Analyzing customer categories and their market share.

---

## Advanced SQL Techniques Demonstrated
* **Window Functions:** Heavy use of `LAG()`, `DENSE_RANK()`, `ROW_NUMBER()`, and `SUM() OVER`.
* **Complex CTEs:** Multi-layered Common Table Expressions for readable and efficient logic.
* **Report Styling:** Using `ROLLUP` for sub-totals (Q7) and `PIVOT` for matrix reporting (Q8).
* **Data Transformation:** Implementing `STRING_AGG`, `CAST`, and complex `CASE WHEN` logic.

---

## Technical Implementation
* **Schemas Handled:** `Sales`, `Warehouse`, `Purchasing`, and `Application`.
* **Data Integrity:** Used `ISNULL` and `NULLIF` to handle missing data and prevent division-by-zero errors.
* **Formatting:** Used `FORMAT` for professional percentage and currency displays.

---

## Resources
* **Dataset Source:** [Wide World Importers on Kaggle](https://www.kaggle.com/datasets/heeraldedhia/wide-world-importers)
* **Code:** [WWI_Analysis_Queries.sql](./WWI_Analysis_Queries.sql)

---

## Note on Data
The analysis was performed on the WWI sample database provided by Microsoft, which simulates a real-world supply chain and trading environment.
