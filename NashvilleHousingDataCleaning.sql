/*

Project on Cleaning Data in SQL Queries

Skills used: Data Cleaning & Transformation, SQL Joins & Self-Joins, Window Functions, CTE, String Manipulation & Parsing,
			Conditional Logic with CASE, Handling Nulls, Schema Alteration (Add/Drop Columns), Data Type Conversion,
			Duplicate Detection & Removal

*/




--Standardize Data Format

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

Select SaleDateConverted, CONVERT(Date, SaleDate)
From portfolioProject..NashvilleHousing



-- Populate Property Address Data

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM portfolioProject..NashvilleHousing a
JOIN portfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null



--Breaking out Adddress into individual columns (Address, City, State)

--FOR PROPERTY ADDRESS
ALTER TABLE NashvilleHousing
DROP COLUMN PropertySplitAddress

ALTER TABLE NashvilleHousing
DROP COLUMN PropertySplitCity

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


--FOR OWNER ADDRESS
ALTER TABLE NashvilleHousing
DROP COLUMN OwnerSplitAddress

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerSplitCity

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerSplitState

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)




--Change Y and N to YES and No in "Sold as Vacant" feild

ALTER TABLE NashvilleHousing
ALTER COLUMN SoldAsVacant VARCHAR(10);

UPDATE NashvilleHousing
SET SoldAsVacant = 
		CASE when SoldAsVacant = '1' THEN 'YES'
		when SoldAsVacant = '0' THEN 'NO'
		ELSE SoldAsVacant
		END





--Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY
						UniqueID
						) row_num

From portfolioProject..NashvilleHousing
)
SELECT *
FROM RowNumCTE 
where row_num > 1
order by PropertyAddress





--Delete Unused Columns

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


