/*
Cleaning Data in SQL Queries
 
The techniques demonstrated here include data type conversions, dealing with NULLs, string manipulation, 
using Common Table Expressions (CTEs) for de-duplication, and modifying the table schema.
*/

-- Attempt to standardize the SaleDate to a proper DATE type
UPDATE "NashvilleHousing"
SET "SaleDate" = "SaleDate"::DATE;

-- Add a new column to capture the standardized SaleDate
ALTER TABLE "NashvilleHousing"
ADD COLUMN "SaleDateConverted" DATE;

-- Populate the new SaleDateConverted column
UPDATE "NashvilleHousing"
SET "SaleDateConverted" = "SaleDate"::DATE;

-- Identify and fill in missing Property Addresses using a self-join on ParcelID
WITH AddressCTE AS (
    SELECT a."ParcelID", COALESCE(a."PropertyAddress", b."PropertyAddress") AS "CorrectedAddress"
    FROM "NashvilleHousing" a
    LEFT JOIN "NashvilleHousing" b ON a."ParcelID" = b."ParcelID" AND a."UniqueID" <> b."UniqueID"
    WHERE a."PropertyAddress" IS NULL
)
UPDATE "NashvilleHousing"
SET "PropertyAddress" = cte."CorrectedAddress"
FROM AddressCTE cte
WHERE "NashvilleHousing"."ParcelID" = cte."ParcelID" AND "NashvilleHousing"."PropertyAddress" IS NULL;

-- Break the PropertyAddress into separate columns for Address and City
ALTER TABLE "NashvilleHousing"
ADD COLUMN "PropertySplitAddress" TEXT,
ADD COLUMN "PropertySplitCity" TEXT;

UPDATE "NashvilleHousing"
SET "PropertySplitAddress" = SPLIT_PART("PropertyAddress", ',', 1),
    "PropertySplitCity" = SPLIT_PART("PropertyAddress", ',', 2);

-- Similarly, let's split the OwnerAddress into Address, City, and State
ALTER TABLE "NashvilleHousing"
ADD COLUMN "OwnerSplitAddress" TEXT,
ADD COLUMN "OwnerSplitCity" TEXT,
ADD COLUMN "OwnerSplitState" TEXT;

UPDATE "NashvilleHousing"
SET "OwnerSplitAddress" = SPLIT_PART("OwnerAddress", ',', 1),
    "OwnerSplitCity" = SPLIT_PART("OwnerAddress", ',', 2),
    "OwnerSplitState" = SPLIT_PART("OwnerAddress", ',', 3);

-- Convert 'Y' and 'N' in the "SoldAsVacant" field to 'Yes' and 'No' for clarity
UPDATE "NashvilleHousing"
SET "SoldAsVacant" = CASE 
                      WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
                      WHEN "SoldAsVacant" = 'N' THEN 'No'
                      ELSE "SoldAsVacant"
                      END;

-- Use a CTE to identify and remove duplicate records
WITH Dupes AS (
    SELECT "UniqueID", ROW_NUMBER() OVER (
        PARTITION BY "ParcelID", "PropertyAddress", "SalePrice", "SaleDateConverted", "LegalReference"
        ORDER BY "UniqueID"
    ) AS row_num
    FROM "NashvilleHousing"
)
DELETE FROM "NashvilleHousing"
WHERE "UniqueID" IN (
    SELECT "UniqueID"
    FROM Dupes
    WHERE row_num > 1
);

-- Clean up the schema by dropping columns that are no longer needed
ALTER TABLE "NashvilleHousing"
DROP COLUMN "OwnerAddress",
DROP COLUMN "TaxDistrict",
DROP COLUMN "PropertyAddress",
DROP COLUMN "SaleDate";
