/*
Data cleaning using SQL
Skills used: UPDATE, ALTER TABLE, SUBSTRING, PARSENAME, DELETE, DROP

*/


SELECT *

FROM [Portfolio Project]..NashvilleHousing

------------------------------------------------------------------------------
--Standardize the Date Format

SELECT 
    SaleDate,
    CONVERT(date,SaleDate) AS 
FROM [Portfolio Project]..NashvilleHousing

--Modify the Date Values with UPDATE

UPDATE NashvilleHousing
SET SaleDate = CONVERT(date,SaleDate)


--If above didn't work modify the table with ALTER TABLE

ALTER TABLE NashvilleHousing
ADD SaleDateConverted date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date,SaleDate)

--To check if the table was succefully updated

SELECT 
    SaleDateConverted
FROM [Portfolio Project]..NashvilleHousing

-------------------------------------------------------------------------------

--Populate property address data

SELECT *
    --PropertyAddress

FROM [Portfolio Project]..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT 
    inc.ParcelID,
    inc.PropertyAddress,
    ref.ParcelID,
    ref.PropertyAddress,
    ISNULL(inc.PropertyAddress,ref.PropertyAddress)

FROM [Portfolio Project]..NashvilleHousing AS inc
JOIN [Portfolio Project]..NashvilleHousing AS ref
    ON inc.ParcelID = ref.ParcelID
    AND inc.[UniqueID ] <> ref.[UniqueID ]
WHERE inc.PropertyAddress IS NULL

UPDATE inc
SET PropertyAddress = ISNULL(inc.PropertyAddress,ref.PropertyAddress)
FROM [Portfolio Project]..NashvilleHousing AS inc
JOIN [Portfolio Project]..NashvilleHousing AS ref
    ON inc.ParcelID = ref.ParcelID
    AND inc.[UniqueID ] <> ref.[UniqueID ]
WHERE inc.PropertyAddress IS NULL

--------------------------------------------------------------------------------------------

--Breaking out Address into Individual Columns (Address, City, State)

SELECT 
    PropertyAddress
FROM [Portfolio Project]..NashvilleHousing


--Break the PropertyAddress by using SUBSTRING function
SELECT  
SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) AS CityAddress
FROM [Portfolio Project]..NashvilleHousing
--------
ALTER TABLE [Portfolio Project]..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE [Portfolio Project]..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1)
--------
ALTER TABLE [Portfolio Project]..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE [Portfolio Project]..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

--Break the OwnerAddress using PARSENAME
SELECT 
    OwnerAddress
FROM [Portfolio Project]..NashvilleHousing
WHERE OwnerAddress IS NOT NULL

----
SELECT

PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)

FROM [Portfolio Project]..NashvilleHousing
WHERE OwnerAddress IS NOT NULL


ALTER TABLE [Portfolio Project]..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE [Portfolio Project]..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)
--------
ALTER TABLE [Portfolio Project]..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE [Portfolio Project]..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)
--------
ALTER TABLE [Portfolio Project]..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE [Portfolio Project]..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

--------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

    SELECT 
        SoldAsVacant,
        COUNT(SoldAsVacant)

    FROM [Portfolio Project]..NashvilleHousing
    GROUP BY SoldAsVacant
    ORDER BY 2

    SELECT 
        SoldAsVacant,
        CASE 
            WHEN SoldAsVacant = 'Y' THEN 'Yes'
            WHEN SoldAsVacant = 'N' THEN 'No'
            ELSE SoldAsVacant
            END 

    FROM [Portfolio Project]..NashvilleHousing

    UPDATE [Portfolio Project]..NashvilleHousing
    SET SoldAsVacant = CASE 
            WHEN SoldAsVacant = 'Y' THEN 'Yes'
            WHEN SoldAsVacant = 'N' THEN 'No'
            ELSE SoldAsVacant
            END 

-------------------------------------------------------------------------

---Remove duplicates

WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER () OVER(
    PARTITION BY ParcelID,
                PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
                ORDER BY 
                    UniqueID
                    ) row_num    
            
FROM [Portfolio Project]..NashvilleHousing
--ORDER BY ParcelID
)
--DELETE
SELECT *
FROM RowNumCTE
WHERE row_num > 1 
ORDER BY PropertyAddress


SELECT *
FROM [Portfolio Project]..NashvilleHousing

---------------------------------------------------------------------------------------

--Delete unused COLUMNS

SELECT *
FROM [Portfolio Project]..NashvilleHousing


ALTER TABLE [Portfolio Project]..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress 

ALTER TABLE [Portfolio Project]..NashvilleHousing
DROP COLUMN SaleDate