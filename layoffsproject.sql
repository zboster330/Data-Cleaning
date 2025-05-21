/* Data Cleaning
1. Remove Duplicates
2. Standardize Data
3. Fix Null and Blank Values
4. Remove Unnescessary Columns and Rows */


-- first create a copy table for safely cleaning the data inside of
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs; 


-- 1. duplicates

-- create another table which has an added row number that can be used to check for duplicates
ALTER TABLE layoffs_staging ADD row_num INT;

CREATE TABLE `layoffs_staging2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
row_num INT
);

-- A row number partition over every column is used to pupulate the row num column because it will increase if every column is the same (a duplicate)
INSERT INTO `layoffs_staging2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		layoffs_staging;

-- now all rows where row_num is greater than 2 can be deleted which deletes all duplicates
DELETE FROM layoffs_staging2
WHERE row_num >= 2;


-- 2. standardizing

-- remove blank space on companies with trim
UPDATE layoffs_staging2
SET company = TRIM(company);

-- multiple spellings of crypto industry, set them all to crypto
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

 -- some country 'united states' entries have an incorrect '.', fix with a trim
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


-- date column is incorrectly formatted as text, change to date format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 3. nulls and blanks

-- there are some blank and null for industry values, but they can be populated by using the company where the company is the same and industry is not(because all equal company values should have equal industry values)
-- first set blanks to nulls
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry ='';

-- use a join to set the null industry values to the industry values of the equal companies
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL)
AND t2.industry IS NOT NULL;


-- 4. remove useless rows and columns

-- previously created row_num column is useless now
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- this dataset is useful for exploring layoff data, therefore, the rows with null values for both total laid off and percent laid off are useless, and should be deleted
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

select * from layoffs_staging2;