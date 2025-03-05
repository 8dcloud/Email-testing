#!/bin/bash

# **************************************************
# *                                                *
# *    8Dweb LLC                                   *
# *    Email Test Script - mjs                     *
# *    Last Update: 03-05-2025                     *
# *    You will be prompted to enter:              *
# *      - mail server, mail recipient, sender     *
# *    Script will then connect via telnet and     *
# *    send. There are sleep commands. Afterwards  *
# *    The script checks a local log file for      *
# *    Errors and outputs findings                 *
# *                                                *
# **************************************************

# Prompt for user input
read -p "Enter Mail Server (IP or hostname): " MAIL_SERVER
read -p "Enter Sender Email Address: " SENDER
read -p "Enter Recipient Email Address: " RECIPIENT

# Check if telnet is installed
if ! command -v telnet &> /dev/null; then
    echo "Error: Telnet is not installed. Please install it using:"
    echo "  Debian/Ubuntu: sudo apt install telnet"
    echo "  CentOS/RHEL: sudo yum install telnet"
    exit 1
fi

# Log file to store output
LOG_FILE="mail_test.log"
echo "Testing connectivity to $MAIL_SERVER on port 25..."
echo "====== SMTP TEST $(date) ======" > "$LOG_FILE"

# Run Telnet commands and capture output
{
    sleep 2
    echo "HELO example.com"
    sleep 1
    echo "MAIL FROM:<$SENDER>"
    sleep 1
    echo "RCPT TO:<$RECIPIENT>"
    sleep 1
    echo "DATA"
    sleep 1
    echo "Subject: Test Email"
    echo "This is a **TEST** email sent by 8Dweb Support via Telnet."
    echo "."
    sleep 1
    echo "QUIT"
} | telnet $MAIL_SERVER 25 | tee -a "$LOG_FILE"

echo "Test completed. Results are saved in $LOG_FILE."

# Analyze the log for common errors
if grep -q "Connection refused" "$LOG_FILE"; then
    echo "❌ Connection refused. Possible reasons:"
    echo "   - The mail server is not running or listening on port 25."
    echo "   - Firewall or ISP is blocking port 25."
    echo "   - Use 'telnet $MAIL_SERVER 25' manually to confirm."
elif grep -q "554" "$LOG_FILE"; then
    echo "❌ Mail rejected (554 error). Possible reasons:"
    echo "   - Mail server is rejecting unauthenticated senders."
    echo "   - The mail server is blacklisting your IP."
    echo "   - Check SPF, DKIM, and DMARC settings."
elif grep -q "530" "$LOG_FILE"; then
    echo "❌ Authentication required (530 error). Possible reasons:"
    echo "   - The mail server requires authentication for outgoing mail."
    echo "   - You need to enable SMTP authentication."
elif grep -q "450" "$LOG_FILE"; then
    echo "⚠️  Temporary mail rejection (450 error). Possible reasons:"
    echo "   - Recipient mailbox is full or temporarily unavailable."
    echo "   - Mail server is throttling incoming messages."
elif grep -q "250 2.0.0 Ok" "$LOG_FILE"; then
    echo "✅ Mail server accepted the message successfully!"
else
    echo "⚠️ No clear response detected. Check '$LOG_FILE' for details."
fi
