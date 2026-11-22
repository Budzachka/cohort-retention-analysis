# User Retention Analysis: Cohort Analysis (SQL + Google Sheets)

## Goal
Evaluate user retention (Retention Rate) using cohort analysis and compare
the behavior of promo users and organic users.

## Tools
- DBevear (PostrgeSQL): data cleaning, date parsing, cohort calculation
- Google Sheets: cohort tables, conditional formatting, interactive filters

## What I did
1. Cleaned raw user and event data; standardized dates stored in different formats
2. Filtered events and joined user and event tables
3. Defined signup cohorts and calculated month offset (user lifetime)
4. Built a cohort table in Google Sheets with Retention Rate by month
5. Compared promo vs organic users and analyzed acquisition quality

Result:

https://docs.google.com/spreadsheets/d/1hosmCr9zr3cQOy0D8YTROz-khHgwE0Wbgj54wncUCb4/edit?usp=sharing
