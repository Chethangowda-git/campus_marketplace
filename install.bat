@echo off
echo Installing Python packages...
pip install -r requirements.txt

echo.
echo [IMPORTANT] You need to manually install ODBC Driver 18:
echo Download from: https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server
echo.
echo After installing ODBC Driver, run: streamlit run app.py
pause
