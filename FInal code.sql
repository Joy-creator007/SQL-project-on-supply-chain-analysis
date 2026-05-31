
USE SQL_Project; 


-- Safely dismantle active foreign key constraints to completely bypass dropping locks
IF OBJECT_ID('dbo.shipments', 'F') IS NOT NULL 
    ALTER TABLE dbo.shipments DROP CONSTRAINT FK__shipments__order__6FE99F9F, FK__shipments__carri__70DDC3D8, FK__shipments__origi__71D1E811;
IF OBJECT_ID('dbo.customer_orders', 'F') IS NOT NULL 
    ALTER TABLE dbo.customer_orders DROP CONSTRAINT FK__customer___custo__68487DD7, FK__customer___produ__693C8210;
IF OBJECT_ID('dbo.production_runs', 'F') IS NOT NULL 
    ALTER TABLE dbo.production_runs DROP CONSTRAINT FK__productio__produ__619B8048, FK__productio__wareh__628FA481;
IF OBJECT_ID('dbo.bill_of_materials', 'F') IS NOT NULL 
    ALTER TABLE dbo.bill_of_materials DROP CONSTRAINT FK__bill_of_m__produ__5BE2A6F2, FK__bill_of_m__mater__5CD6CB2B;
IF OBJECT_ID('dbo.material_inventory', 'F') IS NOT NULL 
    ALTER TABLE dbo.material_inventory DROP CONSTRAINT FK__material___wareh__5535A963, FK__material___mater__5629CD9C;
IF OBJECT_ID('dbo.purchase_orders', 'F') IS NOT NULL 
    ALTER TABLE dbo.purchase_orders DROP CONSTRAINT FK__purchase___suppl__4E88ABD4, FK__purchase___mater__4F7CD00D;

-- Drop existing tables in reverse relational dependency order
IF OBJECT_ID('dbo.shipments', 'U') IS NOT NULL DROP TABLE dbo.shipments;
IF OBJECT_ID('dbo.customer_orders', 'U') IS NOT NULL DROP TABLE dbo.customer_orders;
IF OBJECT_ID('dbo.customers', 'U') IS NOT NULL DROP TABLE dbo.customers;
IF OBJECT_ID('dbo.production_runs', 'U') IS NOT NULL DROP TABLE dbo.production_runs;
IF OBJECT_ID('dbo.bill_of_materials', 'U') IS NOT NULL DROP TABLE dbo.bill_of_materials;
IF OBJECT_ID('dbo.finished_products', 'U') IS NOT NULL DROP TABLE dbo.finished_products;
IF OBJECT_ID('dbo.material_inventory', 'U') IS NOT NULL DROP TABLE dbo.material_inventory;
IF OBJECT_ID('dbo.warehouses', 'U') IS NOT NULL DROP TABLE dbo.warehouses;
IF OBJECT_ID('dbo.purchase_orders', 'U') IS NOT NULL DROP TABLE dbo.purchase_orders;
IF OBJECT_ID('dbo.raw_materials', 'U') IS NOT NULL DROP TABLE dbo.raw_materials;
IF OBJECT_ID('dbo.suppliers', 'U') IS NOT NULL DROP TABLE dbo.suppliers;
IF OBJECT_ID('dbo.logistics_carriers', 'U') IS NOT NULL DROP TABLE dbo.logistics_carriers;




-- 1. Procurement Sphere
CREATE TABLE suppliers (
    supplier_id INT IDENTITY(1,1) PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    lead_time_days INT DEFAULT 7
);

CREATE TABLE raw_materials (
    material_id INT IDENTITY(1,1) PRIMARY KEY,
    material_name VARCHAR(100) NOT NULL,
    sku VARCHAR(50) UNIQUE NOT NULL,
    unit_cost DECIMAL(10, 2) NOT NULL,
    reorder_level INT NOT NULL
);

CREATE TABLE purchase_orders (
    po_id INT IDENTITY(1,1) PRIMARY KEY,
    supplier_id INT FOREIGN KEY REFERENCES suppliers(supplier_id),
    material_id INT FOREIGN KEY REFERENCES raw_materials(material_id),
    quantity_ordered INT NOT NULL,
    order_date DATE DEFAULT GETDATE(),
    status VARCHAR(20) CHECK (status IN ('Pending', 'Shipped', 'Received', 'Cancelled'))
);

-- 2. Warehousing Sphere
CREATE TABLE warehouses (
    warehouse_id INT IDENTITY(1,1) PRIMARY KEY,
    warehouse_name VARCHAR(100) NOT NULL,
    location VARCHAR(100)
);

CREATE TABLE material_inventory (
    warehouse_id INT FOREIGN KEY REFERENCES warehouses(warehouse_id),
    material_id INT FOREIGN KEY REFERENCES raw_materials(material_id),
    quantity_on_hand INT DEFAULT 0,
    PRIMARY KEY (warehouse_id, material_id)
);

-- 3. Production Sphere
CREATE TABLE finished_products (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    product_sku VARCHAR(50) UNIQUE NOT NULL,
    selling_price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE bill_of_materials (
    product_id INT FOREIGN KEY REFERENCES finished_products(product_id),
    material_id INT FOREIGN KEY REFERENCES raw_materials(material_id),
    quantity_required INT NOT NULL,
    PRIMARY KEY (product_id, material_id)
);

-- 4. Commercial Sales Sphere
CREATE TABLE customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    segment VARCHAR(50) CHECK (segment IN ('Wholesale', 'Retail'))
);

CREATE TABLE customer_orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT FOREIGN KEY REFERENCES customers(customer_id),
    product_id INT FOREIGN KEY REFERENCES finished_products(product_id),
    quantity_ordered INT NOT NULL,
    order_date DATE DEFAULT GETDATE(),
    order_status VARCHAR(20) CHECK (order_status IN ('Processing', 'Shipped', 'Delivered', 'Returned'))
);

-- 5. Outbound Logistics Sphere
CREATE TABLE logistics_carriers (
    carrier_id INT IDENTITY(1,1) PRIMARY KEY,
    carrier_name VARCHAR(100) NOT NULL,
    transport_mode VARCHAR(20) CHECK (transport_mode IN ('Air', 'Sea', 'Rail', 'Road'))
);

CREATE TABLE shipments (
    shipment_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT FOREIGN KEY REFERENCES customer_orders(order_id),
    carrier_id INT FOREIGN KEY REFERENCES logistics_carriers(carrier_id),
    origin_warehouse_id INT FOREIGN KEY REFERENCES warehouses(warehouse_id),
    ship_date DATE NOT NULL,
    actual_delivery_date DATE,
    shipping_cost DECIMAL(10, 2) NOT NULL
);


-- Seed Master Catalog
INSERT INTO suppliers (supplier_name, country, lead_time_days) VALUES 
('Global Steel Inc', 'USA', 10), ('Apex Plastics', 'Germany', 5), ('Sino Tech Materials', 'China', 15);

INSERT INTO warehouses (warehouse_name, location) VALUES 
('Midwest Logistics Hub', 'Chicago'), ('Euro Storage Depot', 'Rotterdam');

INSERT INTO logistics_carriers (carrier_name, transport_mode) VALUES 
('FedEx Freight', 'Road'), ('Maersk Line', 'Sea'), ('DHL Express', 'Air');

-- Generate 50 Raw Materials
WITH RowGen AS (
    SELECT 1 AS n UNION ALL SELECT n + 1 FROM RowGen WHERE n < 50
)
INSERT INTO raw_materials (material_name, sku, unit_cost, reorder_level)
SELECT 
    'Raw Material ' + CAST(n AS VARCHAR),
    'MAT-SKU-' + RIGHT('00' + CAST(n AS VARCHAR), 3),
    CAST((10 + (n * 1.5)) AS DECIMAL(10,2)),
    500 + (n * 10) 
FROM RowGen 
OPTION (MAXRECURSION 100);

-- Generate 50 Finished Products
WITH RowGen AS (
    SELECT 1 AS n UNION ALL SELECT n + 1 FROM RowGen WHERE n < 50
)
INSERT INTO finished_products (product_name, product_sku, selling_price)
SELECT 
    'Enterprise Product ' + CAST(n AS VARCHAR),
    'PROD-SKU-' + RIGHT('00' + CAST(n AS VARCHAR), 3),
    CAST((150 + (n * 12.5)) AS DECIMAL(10,2)) 
FROM RowGen 
OPTION (MAXRECURSION 100);

-- Bills of Materials (BOM)
INSERT INTO bill_of_materials (product_id, material_id, quantity_required)
SELECT p.product_id, m.material_id, (p.product_id % 4) + 1 
FROM finished_products p 
CROSS JOIN raw_materials m 
WHERE m.material_id = p.product_id OR m.material_id = (p.product_id + 1);

-- Inventory Stocking Across Distribution Centers
INSERT INTO material_inventory (warehouse_id, material_id, quantity_on_hand) 
SELECT 1, material_id, ABS(CHECKSUM(NEWID()) % 1500) + 200 FROM raw_materials;

INSERT INTO material_inventory (warehouse_id, material_id, quantity_on_hand) 
SELECT 2, material_id, ABS(CHECKSUM(NEWID()) % 1200) + 100 FROM raw_materials;

-- Generate 100 Commercial Corporate Clients
WITH RowGen AS (
    SELECT 1 AS n UNION ALL SELECT n + 1 FROM RowGen WHERE n < 100
)
INSERT INTO customers (customer_name, segment) 
SELECT 'Client Corp ' + CAST(n AS VARCHAR), CASE WHEN n % 2 = 0 THEN 'Wholesale' ELSE 'Retail' END FROM RowGen;

-- RECURSIVE TRANSACTION GENERATOR: 2,500 TRANSACTIONS SPANNING 2025 - 2026
WITH OrderGen AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM OrderGen WHERE n < 2500
)
INSERT INTO customer_orders (customer_id, product_id, quantity_ordered, order_date, order_status)
SELECT 
    (n % 100) + 1,                                        
    (n % 50) + 1,                                         
    (n % 15) + 1,                                         
    DATEADD(DAY, -(n * 0.25), '2026-05-29'),               
    CASE WHEN n % 14 = 0 THEN 'Returned' ELSE 'Delivered' END
FROM OrderGen
OPTION (MAXRECURSION 2500);

-- Pipe Corresponding for Finished Outbound Sales
INSERT INTO shipments (order_id, carrier_id, origin_warehouse_id, ship_date, actual_delivery_date, shipping_cost)
SELECT 
    order_id,
    (order_id % 3) + 1,
    (order_id % 2) + 1,
    order_date,
    DATEADD(DAY, (order_id % 4) + 1, order_date),
    CAST((40 + (order_id % 150) * 3.1) AS DECIMAL(10,2))
FROM customer_orders 
WHERE order_status = 'Delivered';






-- ANALYSIS 1: YEAR-ON-YEAR (YoY) SALES, COST, AND PROFIT MARGIN PERFORMANCE';


WITH ProductCosting AS (
    SELECT bom.product_id, SUM(bom.quantity_required * rm.unit_cost) AS material_cost_per_unit
    FROM bill_of_materials bom 
    JOIN raw_materials rm ON bom.material_id = rm.material_id 
    GROUP BY bom.product_id
),
YearlyMetrics AS (
    SELECT 
        YEAR(co.order_date) AS fiscal_year,
        SUM(co.quantity_ordered) AS units_sold,
        SUM(co.quantity_ordered * fp.selling_price) AS gross_revenue,
        SUM(co.quantity_ordered * pc.material_cost_per_unit) AS direct_material_costs,
        SUM(COALESCE(s.shipping_cost, 0)) AS direct_logistics_costs
    FROM customer_orders co
    JOIN finished_products fp ON co.product_id = fp.product_id
    JOIN ProductCosting pc ON fp.product_id = pc.product_id
    LEFT JOIN shipments s ON co.order_id = s.order_id
    WHERE co.order_status = 'Delivered'
    GROUP BY YEAR(co.order_date)
)
SELECT 
    curr.fiscal_year AS [Fiscal Year],
    FORMAT(curr.units_sold, '#,##0') AS [Units Sold],
    FORMAT(curr.gross_revenue, 'C', 'en-US') AS [Gross Revenue],
    FORMAT(curr.gross_revenue - prev.gross_revenue, 'C', 'en-US') AS [YoY Revenue Growth ($)],
    CAST(((curr.gross_revenue - prev.gross_revenue) / prev.gross_revenue) * 100 AS DECIMAL(5,2)) AS [YoY Revenue Growth (%)],
    FORMAT(curr.gross_revenue - curr.direct_material_costs - curr.direct_logistics_costs, 'C', 'en-US') AS [Net Profit Contribution],
    CAST(((curr.gross_revenue - curr.direct_material_costs - curr.direct_logistics_costs) / curr.gross_revenue) * 100 AS DECIMAL(5,2)) AS [Net Profit Margin %]
FROM YearlyMetrics curr
LEFT JOIN YearlyMetrics prev ON curr.fiscal_year = prev.fiscal_year + 1;


-- 'ANALYSIS 2: TOP 5 PROFIT-DRIVING FINISHED PRODUCTS';

WITH ProductCosting AS (
    SELECT bom.product_id, SUM(bom.quantity_required * rm.unit_cost) AS material_cost_per_unit
    FROM bill_of_materials bom 
    JOIN raw_materials rm ON bom.material_id = rm.material_id 
    GROUP BY bom.product_id
)
SELECT TOP 5
    fp.product_name AS [Product Name],
    SUM(co.quantity_ordered) AS [Total Units Shipped],
    FORMAT(SUM(co.quantity_ordered * fp.selling_price), 'C', 'en-US') AS [Cumulative Revenue],
    FORMAT(SUM(co.quantity_ordered * fp.selling_price) - SUM(co.quantity_ordered * pc.material_cost_per_unit) - SUM(COALESCE(s.shipping_cost, 0)), 'C', 'en-US') AS [Product Net Profit],
    CAST((SUM(co.quantity_ordered * fp.selling_price) - SUM(co.quantity_ordered * pc.material_cost_per_unit) - SUM(COALESCE(s.shipping_cost, 0))) / SUM(co.quantity_ordered * fp.selling_price) * 100 AS DECIMAL(5,2)) AS [Product Margin %]
FROM customer_orders co
JOIN finished_products fp ON co.product_id = fp.product_id
JOIN ProductCosting pc ON fp.product_id = pc.product_id
LEFT JOIN shipments s ON co.order_id = s.order_id
WHERE co.order_status = 'Delivered'
GROUP BY fp.product_name
ORDER BY SUM(co.quantity_ordered * fp.selling_price) - SUM(co.quantity_ordered * pc.material_cost_per_unit) - SUM(COALESCE(s.shipping_cost, 0)) DESC;
