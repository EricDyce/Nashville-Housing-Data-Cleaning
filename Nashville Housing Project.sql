SELECT *
FROM Nashville
order by PropertyAddress

-- Standardize date format
SELECT SaleDate, CONVERT(date, SaleDate)
FROM Nashville

ALTER TABLE Nashville
ALTER COLUMN SaleDate date

-- alternatively ---------------------
ALTER TABLE Nashville
ADD SaleDate2 date

UPDATE Nashville
SET SaleDate2 = CONVERT(date, SaleDate)
---------------------------------------------------------------------------------------------------

-- Populate Proterty Address data

SELECT a.[UniqueID ], b.[UniqueID ], a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress,
ISNULL(a.PropertyAddress, b.PropertyAddress) --ISNULL(x,y) fills x with the corresponding value of y whr x is null
FROM Nashville a
JOIN Nashville b
ON  a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
--WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Nashville a
JOIN Nashville b
ON  a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

--We could use ISNULL(a.PropertyAddress,"No Address") if we wanted to populate null values with the string "No Address"
-------------------------------------------------------------------------------------------------------------------------

-- Here we are splitting the comma delimited PropertyAddress column into Prop and Addr
SELECT
SUBSTRING(PropertyAddress, 1, (charindex(',', PropertyAddress)-1)) AS Property,
SUBSTRING(PropertyAddress,(charindex(',', PropertyAddress)+1), LEN(PropertyAddress)) AS Address
FROM Nashville

-- charindex(x,y) returns the index position of the character x in string y

ALTER TABLE Nashville
ADD Property nvarchar(250)

UPDATE Nashville
SET Property = SUBSTRING(PropertyAddress, 1, (charindex(',', PropertyAddress)-1))

ALTER TABLE Nashville
ADD Address nvarchar(250)

UPDATE Nashville
SET Address = SUBSTRING(PropertyAddress,(charindex(',', PropertyAddress)+1), LEN(PropertyAddress))
---------------------------------------------------------------------------------------------------------------

-- Alternative to split string is PARSENAME, but uses period(.) delimeter

SELECT 
PARSENAME(OwnerAddress, 1)
FROM Nashville 
-- This returns the column unaltered 'cos its delimited by , instead of . for Parsename to work, hence we replace , with .
SELECT 
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
FROM Nashville 
-- This returns an altered column, but the last part ... the parsename function works in reverse,so last comes first
SELECT 
PARSENAME(REPLACE(OwnerAddress,',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
FROM Nashville 

ALTER TABLE Nashville
ADD 
OwnerArea nvarchar(250),
OwnerCity nvarchar(250),
OwnerState nvarchar(250)

UPDATE Nashville
SET
OwnerArea = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3),
OwnerCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
OwnerState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)

SELECT * FROM Nashville
-------------------------------------------------------------------------------------------------------------------------------

Select DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashville
GROUP BY SoldAsVacant
-- returns Yes, Y, No, and N ... we'll make all Y's Yes and all N's No for uniformity

SELECT 
CASE SoldAsVacant
WHEN 'N' THEN 'No'
WHEN 'Y' THEN 'Yes'
ELSE SoldAsVacant
END 
FROM Nashville
WHERE SoldAsVacant = 'y'


UPDATE Nashville
SET SoldAsVacant = 
CASE SoldAsVacant
WHEN 'N' THEN 'No'
WHEN 'Y' THEN 'Yes'
ELSE SoldAsVacant
END 
FROM Nashville
-------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

With RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				PropertyAddress, 
				SaleDate, 
				SalePrice, 
				LegalReference 
	ORDER BY UniqueID)row_num
FROM Nashville_Housing..Nashville
)
SELECT * FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- This returns all duplicate rows from the table, next we delete them

With RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				PropertyAddress, 
				SaleDate, 
				SalePrice, 
				LegalReference 
	ORDER BY UniqueID)row_num
FROM Nashville_Housing..Nashville
)
DELETE FROM RowNumCTE
WHERE row_num > 1
-------------------------------------------------------------------------------------------------------------------------------------

-- Deleting unused columns
-- Don't do this on ur raw data .... at least not without authorization, rather use it in views

SELECT *
FROM Nashville

ALTER TABLE Nashville
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict