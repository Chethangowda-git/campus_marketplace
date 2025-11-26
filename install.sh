#!/bin/bash

echo "Installing Python packages..."
pip3 install -r requirements.txt

echo "Installing ODBC Driver for SQL Server..."
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release 2>/dev/null
brew update
brew install msodbcsql18 mssql-tools18

echo "✅ Installation complete! Run: streamlit run app.py"
