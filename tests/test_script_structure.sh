#!/bin/bash
#
# Basic test to verify the structure and correctness of monitor_status.sh
# This doesn't run the monitoring functionality but checks for common issues
#

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "Running structural tests for monitor_status.sh..."
echo ""

# Check that the script exists
if [ ! -f "monitor_status.sh" ]; then
    echo -e "${RED}FAIL:${NC} monitor_status.sh file not found"
    exit 1
fi

# Check that the script is executable
if [ ! -x "monitor_status.sh" ]; then
    echo -e "${YELLOW}WARN:${NC} monitor_status.sh is not executable"
    echo "  Fix with: chmod +x monitor_status.sh"
fi

# Check for basic syntax errors with bash -n
echo -n "Checking for syntax errors... "
if bash -n monitor_status.sh; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Check that required sections exist
echo -n "Checking for required code sections... "
MISSING_SECTIONS=0

if ! grep -q "SETUP AND CONFIGURATION" monitor_status.sh; then
    echo -e "\n${YELLOW}WARN:${NC} Missing SETUP AND CONFIGURATION section"
    MISSING_SECTIONS=$((MISSING_SECTIONS+1))
fi

if ! grep -q "MAIN MONITORING LOOP" monitor_status.sh; then
    echo -e "\n${YELLOW}WARN:${NC} Missing MAIN MONITORING LOOP section"
    MISSING_SECTIONS=$((MISSING_SECTIONS+1))
fi

if [ $MISSING_SECTIONS -eq 0 ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${YELLOW}WARN:${NC} Missing some recommended code sections"
fi

# Check for potential issues
echo -n "Checking for potential problematic patterns... "
ISSUES=0

# Check for rm -rf / patterns that could be dangerous
if grep -q "rm -rf \/" monitor_status.sh; then
    echo -e "\n${RED}FAIL:${NC} Script contains potentially dangerous 'rm -rf /' pattern"
    ISSUES=$((ISSUES+1))
fi

# Check for use of sudo
if grep -q "\sudo " monitor_status.sh; then
    echo -e "\n${YELLOW}WARN:${NC} Script contains 'sudo' commands which may require user interaction"
    ISSUES=$((ISSUES+1))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}PASS${NC}"
fi

# Check for common commands used
echo -e "\nChecking for required commands..."
for cmd in uptime ps vm_stat awk grep sed; do
    if grep -q "\b$cmd\b" monitor_status.sh; then
        echo -e "  ${GREEN}✓${NC} Uses $cmd"
    else
        echo -e "  ${YELLOW}?${NC} Does not use $cmd (may not be an issue)"
    fi
done

# Final summary
echo -e "\n${GREEN}Structural tests completed.${NC}"
echo "Note: This does not guarantee functionality, but checks for common issues."
echo "For complete testing, use the test_monitor.sh script."
