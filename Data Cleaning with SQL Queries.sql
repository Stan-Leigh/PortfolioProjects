/*
Cleaning Data in SQL Queries
*/


--------------------------------------------------------------------------------------------------------------------------
-- Replacing empty columns with NULL

-- The query below gets the UPDATE and SET queries for all the columns so I don't have to write it out myself
SELECT 'UPDATE PortfolioProject.dbo.NashvilleHousing SET ' + name + ' = NULL WHERE ' + name + ' = '''';'
FROM syscolumns
WHERE id = object_id('PortfolioProject.dbo.NashvilleHousing')
  AND isnullable = 1;

UPDATE PortfolioProject.dbo.NashvilleHousing SET UniqueID  = NULL WHERE UniqueID  = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET ParcelID = NULL WHERE ParcelID = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET LandUse = NULL WHERE LandUse = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET PropertyAddress = NULL WHERE PropertyAddress = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET SaleDate = NULL WHERE SaleDate = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET SalePrice = NULL WHERE SalePrice = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET LegalReference = NULL WHERE LegalReference = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET SoldAsVacant = NULL WHERE SoldAsVacant = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET OwnerAddress = NULL WHERE OwnerAddress = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET Acreage = NULL WHERE Acreage = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET TaxDistrict = NULL WHERE TaxDistrict = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET LandValue = NULL WHERE LandValue = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET BuildingValue = NULL WHERE BuildingValue = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET TotalValue = NULL WHERE TotalValue = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET YearBuilt = NULL WHERE YearBuilt = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET Bedrooms = NULL WHERE Bedrooms = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET FullBath = NULL WHERE FullBath = '';
UPDATE PortfolioProject.dbo.NashvilleHousing SET HalfBath = NULL WHERE HalfBath = '';

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;


--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


SELECT SaleDate, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing;


UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate);



 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL;

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID;

-- It can be seen that houses with the same ParcelID has the same PropertyAddress. 
-- So we can use ParcelID with PropertyAddress to fill in null PropertyAddress with the same ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;



--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing;

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1 ) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address

FROM PortfolioProject.dbo.NashvilleHousing;


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 );


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress));


SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;


-- Simpler way to split a column into two or more columns

SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing;


SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM PortfolioProject.dbo.NashvilleHousing;


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255),
	OwnerSplitCity NVARCHAR(255), 
	OwnerSplitState NVARCHAR(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);


SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;



--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;




SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject.dbo.NashvilleHousing;


UPDATE PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM PortfolioProject.dbo.NashvilleHousing

)
DELETE
FROM RowNumCTE
WHERE row_num > 1;
-- ORDER BY PropertyAddress



SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;



---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


SELECT *
FROM PortfolioProject.dbo.NashvilleHousing;


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;