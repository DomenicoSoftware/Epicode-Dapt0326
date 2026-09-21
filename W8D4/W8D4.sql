Create DATABASE ToysGroup;
USE ToysGroup;

-- 2 creazione tabelle
CREATE TABLE Product (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50) NOT NULL,
    CategoryName VARCHAR(50) NOT NULL
);

CREATE TABLE Region (
    RegionID INT PRIMARY KEY,
    State VARCHAR(50) NOT NULL,
    RegionName VARCHAR(50) NOT NULL
);

CREATE TABLE Sales (
    SalesID INT PRIMARY KEY,
    ProductID INT NOT NULL,
    RegionID INT NOT NULL,
    SaleDate DATE NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10, 2) NOT NULL,
    SalesAmount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (RegionID) REFERENCES Region(RegionID)
);

-- 3 popolamento dati
INSERT INTO Product (ProductID, ProductName, CategoryName) VALUES
(101, 'Bikes-100', 'Bikes'),
(102, 'Bikes-200', 'Bikes'),
(103, 'Action Figure Hero', 'Toys'),
(104, 'Board Game Classic', 'Games'),
(105, 'Puzzle Deluxe', 'Games');

INSERT INTO Region (RegionID, State, RegionName) VALUES
(1, 'France', 'WestEurope'),
(2, 'Germany', 'WestEurope'),
(3, 'Italy', 'SouthEurope'),
(4, 'Spain', 'SouthEurope');

INSERT INTO Sales (SalesID, ProductID, RegionID, SaleDate, Quantity, UnitPrice, SalesAmount) VALUES
(1,  101, 1, '2023-03-15', 2, 120.00, 240.00),
(2,  101, 2, '2023-06-20', 1, 120.00, 120.00),
(3,  102, 1, '2023-11-05', 3, 250.00, 750.00),
(4,  103, 3, '2023-12-01', 5,  25.00, 125.00),
(5,  104, 4, '2024-01-10', 4,  35.00, 140.00),
(6,  101, 3, '2024-02-18', 2, 120.00, 240.00),
(7,  102, 2, '2024-04-12', 1, 250.00, 250.00),
(8,  103, 1, '2024-05-30', 6,  25.00, 150.00),
(9,  104, 2, '2024-07-22', 2,  35.00,  70.00),
(10, 102, 3, '2024-08-14', 2, 250.00, 500.00),
(11, 101, 1, '2024-09-02', 3, 120.00, 360.00),
(12, 103, 4, '2024-10-10', 4,  25.00, 100.00);

SELECT * FROM Product;
SELECT * FROM Region;
SELECT * FROM Sales;

-- 4a verifica unicità
SELECT ProductID, COUNT(*) AS Conteggio
FROM Product
GROUP BY ProductID
HAVING COUNT(*) > 1;

SELECT RegionID, COUNT(*) AS Conteggio
FROM Region
GROUP BY RegionID
HAVING COUNT(*) > 1;

SELECT SalesID, COUNT(*) AS Conteggio
FROM Sales
GROUP BY SalesID
HAVING COUNT(*) > 1;

-- aggregazioni e raggruppamenti
SELECT 
    s.SalesID,
    p.ProductID,
    p.CategoryName,
    r.State,
    r.RegionName,
    s.SaleDate,
    CASE 
        WHEN DATEDIFF(CURRENT_DATE, s.SaleDate) > 180 THEN 'True'
        ELSE 'False'
    END AS Oltre180Giorni
FROM Sales AS s
INNER JOIN Product AS p ON s.ProductID = p.ProductID
INNER JOIN Region AS r ON s.RegionID = r.RegionID;

SELECT COUNT(*) AS ConteggioRigheJoin
FROM Sales AS s
INNER JOIN Product AS p ON s.ProductID = p.ProductID
INNER JOIN Region AS r ON s.RegionID = r.RegionID;

SELECT COUNT(*) AS ConteggioRigheSales FROM Sales;

-- 4b fatturato totale e Quantità venduta per Anno
SELECT 
    YEAR(SaleDate) AS Anno,
    SUM(Quantity) AS TotalePezziVenduti,
    SUM(SalesAmount) AS FatturatoTotale
FROM Sales
GROUP BY YEAR(SaleDate)
ORDER BY Anno;

-- fatturato totale e quantità venduta per categoria e anno
SELECT 
    p.CategoryName,
    YEAR(s.SaleDate) AS Anno,
    SUM(s.Quantity) AS TotalePezziVenduti,
    SUM(s.SalesAmount) AS FatturatoTotale
FROM Sales AS s
INNER JOIN Product AS p ON s.ProductID = p.ProductID
GROUP BY p.CategoryName, YEAR(s.SaleDate)
ORDER BY p.CategoryName, Anno;

-- fatturato e quantità per stato e anno e uniamo sales a region per avere lo stato
SELECT 
    r.State,
    YEAR(s.SaleDate) AS Anno,
    SUM(s.Quantity) AS TotalePezziVenduti,
    SUM(s.SalesAmount) AS FatturatoTotale
FROM Sales AS s
INNER JOIN Region AS r ON s.RegionID = r.RegionID
GROUP BY r.State, YEAR(s.SaleDate)
HAVING Anno != 2023 -- per esempio
ORDER BY FatturatoTotale DESC;

-- categoria più richiesta pezzi venduti complessivi
SELECT 
    p.CategoryName,
    SUM(s.Quantity) AS TotalePezziVenduti
FROM Sales AS s
INNER JOIN Product AS p ON s.ProductID = p.ProductID
GROUP BY p.CategoryName
ORDER BY TotalePezziVenduti DESC
LIMIT 1;

-- 4c prodotti venduti sopra la media
SELECT 
    ProductID,
    SUM(Quantity) AS TotaleVenduto
FROM Sales
WHERE YEAR(SaleDate) = (SELECT MAX(YEAR(SaleDate)) FROM Sales)
GROUP BY ProductID
HAVING SUM(Quantity) > (
    SELECT AVG(TotalePerProdotto)
    FROM (
        SELECT SUM(Quantity) AS TotalePerProdotto
        FROM Sales
        WHERE YEAR(SaleDate) = (SELECT MAX(YEAR(SaleDate)) FROM Sales)
        GROUP BY ProductID
    ) AS CalcoloMedia
);

-- riscritta
WITH VenditeUltimoAnno AS (
    SELECT 
        ProductID,
        SUM(Quantity) AS TotaleVenduto
    FROM Sales
    WHERE YEAR(SaleDate) = (SELECT MAX(YEAR(SaleDate)) FROM Sales)
    GROUP BY ProductID
)
SELECT 
    ProductID,
    TotaleVenduto
FROM VenditeUltimoAnno
WHERE TotaleVenduto > (
    SELECT AVG(TotaleVenduto) 
    FROM VenditeUltimoAnno
);

-- 4d window function, class.
WITH TransazioniRegione AS (
    SELECT 
        s.SalesID,
        s.SaleDate,
        p.ProductName,
        p.CategoryName,
        r.State,
        s.RegionID,
        s.SalesAmount,
        
-- classifica per fatturato
        RANK() OVER (
            PARTITION BY p.CategoryName 
            ORDER BY s.SalesAmount DESC
        ) AS ClassificaCategoria,
        
-- totale progressivo del fatturato fino a quella data nella regione
        SUM(s.SalesAmount) OVER (
            PARTITION BY s.RegionID 
            ORDER BY s.SaleDate, s.SalesID
        ) AS ProgressivoRegione,
        
-- assegna un numero sequenziale a ciascuna transazione per regione
        ROW_NUMBER() OVER (
            PARTITION BY s.RegionID 
            ORDER BY s.SaleDate, s.SalesID
        ) AS NumeroOrdineRegione

    FROM Sales AS s
    INNER JOIN Product AS p ON s.ProductID = p.ProductID
    INNER JOIN Region AS r ON s.RegionID = r.RegionID
)
-- confronto con la transazione precedente
SELECT 
    t1.SalesID,
    t1.SaleDate,
    t1.ProductName,
    t1.CategoryName,
    t1.State,
    t1.SalesAmount,
    t1.ClassificaCategoria,
    t1.ProgressivoRegione,
    t2.SalesAmount AS FatturatoPrecedenteRegione
FROM TransazioniRegione AS t1
LEFT JOIN TransazioniRegione AS t2 
    ON t1.RegionID = t2.RegionID 
   AND t1.NumeroOrdineRegione = t2.NumeroOrdineRegione + 1
ORDER BY t1.State, t1.SaleDate;

-- 4e vista prodotti
-- sottrazione per invenduti
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryName
FROM Product AS p
LEFT JOIN Sales AS s ON p.ProductID = s.ProductID
WHERE s.SalesID IS NULL;

-- confr. insiemistico per invenduti
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryName
FROM Product AS p
WHERE p.ProductID NOT IN (
    SELECT DISTINCT ProductID 
    FROM Sales
);

-- vista vers. denormalizzata
CREATE VIEW VistaProdotti AS
SELECT 
    ProductID,
    ProductName,
    CategoryName
FROM Product;

SELECT * FROM VistaProdotti;

-- vista info geografiche
CREATE VIEW VistaVenditeGeografiche AS
SELECT 
    s.SalesID,
    s.SaleDate,
    r.State,
    r.RegionName,
    p.ProductName,
    s.Quantity,
    s.SalesAmount
FROM Sales AS s
INNER JOIN Region AS r ON s.RegionID = r.RegionID
INNER JOIN Product AS p ON s.ProductID = p.ProductID;

SELECT * FROM VistaVenditeGeografiche;