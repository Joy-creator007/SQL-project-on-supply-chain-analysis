# SQL-project-on-supply-chain-analysis
# Enterprise Supply Chain Analytics Engine (T-SQL)

An end-to-end relational database architecture, automated data factory, and Business Intelligence engine designed in Microsoft SQL Server (T-SQL). This project models a complex global supply chain ecosystem across 5 distinct business spheres, automatically generating over 2,500 transactional records to evaluate Year-on-Year (YoY) financial performance and product profitability.

---

## 📌 Project Architecture Overview

This project bypasses basic flat-file data manipulation to build a fully normalized, relational star/snowflake-hybrid schema. The database is defensively engineered with strict domain constraints, referential integrity loops, and composite primary keys to guarantee absolute data quality at the database-engine level.

### The 5 Business Spheres Modeled:
1. **Procurement Sphere:** Evaluates vendor performance, operational country risks, and supplier component lead times.
2. **Warehousing Sphere:** Manages inventory allocation across regional distribution hubs using space-optimizing composite identifiers.
3. **Production Sphere (Manufacturing):** Maps multi-tier component recipes via a structural Bill of Materials (BOM).
4. **Commercial Sales Sphere:** Tracks B2B and B2C market demands across distinct corporate customer segments.
5. **Outbound Logistics Sphere:** Audits carrier performance, transit networks, variable freight overheads, and Service Level Agreements (SLAs).

---

## 🛠️ Relational Database Schema Design

The physical data model contains the following tables and structural design logic:

| Table Name | Entity Type | Primary Key Type | Key Constraints / Operational Safeguards |
| :--- | :--- | :--- | :--- |
| **`suppliers`** | Dimension | Surrogate (`IDENTITY`) | `DEFAULT` operational lead time settings. |
| **`raw_materials`** | Dimension | Surrogate (`IDENTITY`) | `UNIQUE` asset SKU verification; strict `DECIMAL` financial precision. |
| **`purchase_orders`**| Transactional | Surrogate (`IDENTITY`) | Relational `FOREIGN KEY` loops linking suppliers to materials. |
| **`warehouses`** | Dimension | Surrogate (`IDENTITY`) | Facility descriptive identifiers. |
| **`material_inventory`**| Bridge Ledger | **Composite Key** | Dual `FOREIGN KEY` binding preventing duplicate warehouse-to-item pairs. |
| **`finished_products`**| Dimension | Surrogate (`IDENTITY`) | `UNIQUE` commercial product SKUs; exact float-error-free price points. |
| **`bill_of_materials`**| Bridge Recipe | **Composite Key** | Groups items together to mathematically prevent recipe duplication. |
| **`customers`** | Dimension | Surrogate (`IDENTITY`) | Database-level `CHECK` constraint restricting entries to (`Wholesale`, `Retail`). |
| **`customer_orders`** | Transactional | Surrogate (`IDENTITY`) | Strict operational status lifecycle constraints (`Processing`, `Shipped`, `Delivered`, `Returned`). |
| **`logistics_carriers`**| Dimension | Surrogate (`IDENTITY`) | Transport domain constraints (`Air`, `Sea`, `Rail`, `Road`). |
| **`shipments`** | Transactional | Surrogate (`IDENTITY`) | Direct relational alignment tracking actual transit dates and carrier fees. |

---

## 🚀 Key Technical Database Engineering Features

### 1. Idempotent Deployment & Defensive Architecture
The deployment script features an automated teardown-and-initialization lifecycle wrapper. By programmatically dismantling active foreign key constraints by name before execution, it prevents object locking errors and ensures the script can be run repeatedly safely on any fresh SQL instance:
```sql
IF OBJECT_ID('dbo.shipments', 'F') IS NOT NULL 
    ALTER TABLE dbo.shipments DROP CONSTRAINT FK__shipments__order__6FE99F9F...
