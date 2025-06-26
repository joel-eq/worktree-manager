#!/bin/bash

# Test runner for git worktree manager
# Runs all Bats tests with proper setup and reporting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/tests"

# Check if bats is available
check_bats() {
    if ! command -v bats >/dev/null 2>&1; then
        echo -e "${RED}Error: Bats (Bash Automated Testing System) is not installed${NC}"
        echo
        echo "Install Bats:"
        echo "  macOS: brew install bats-core"
        echo "  Ubuntu: sudo apt-get install bats"
        echo "  Or: npm install -g bats"
        echo
        echo "Alternative: Use Docker:"
        echo "  docker run --rm -v \"\$PWD\":/code bats/bats:latest /code/scripts/tests"
        exit 1
    fi
}

# Print header
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Git Worktree Manager Test Suite${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo
}

# Print test file header
print_test_header() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .bats)
    echo -e "${YELLOW}Running: $test_name${NC}"
    echo "File: $test_file"
    echo
}

# Run a single test file
run_test_file() {
    local test_file="$1"
    local verbose="$2"
    
    print_test_header "$test_file"
    
    if [[ "$verbose" == "true" ]]; then
        bats --verbose-run "$test_file"
    else
        bats "$test_file"
    fi
    
    local exit_code=$?
    echo
    
    return $exit_code
}

# Main function
main() {
    local verbose=false
    local specific_test=""
    local failed_tests=()
    local passed_tests=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=true
                shift
                ;;
            -t|--test)
                specific_test="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [options]"
                echo
                echo "Options:"
                echo "  -v, --verbose     Show verbose test output"
                echo "  -t, --test FILE   Run specific test file"
                echo "  -h, --help        Show this help"
                echo
                echo "Examples:"
                echo "  $0                          # Run all tests"
                echo "  $0 --verbose               # Run all tests with verbose output"
                echo "  $0 --test test_core.bats   # Run specific test file"
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    print_header
    
    check_bats
    
    # Verify test directory exists
    if [[ ! -d "$TEST_DIR" ]]; then
        echo -e "${RED}Error: Test directory not found: $TEST_DIR${NC}"
        exit 1
    fi
    
    # Change to script directory for relative path resolution
    cd "$SCRIPT_DIR"
    
    # Run specific test or all tests
    if [[ -n "$specific_test" ]]; then
        local test_path="$TEST_DIR/$specific_test"
        if [[ ! -f "$test_path" ]]; then
            echo -e "${RED}Error: Test file not found: $test_path${NC}"
            exit 1
        fi
        
        if run_test_file "$test_path" "$verbose"; then
            echo -e "${GREEN}✓ $specific_test passed${NC}"
            exit 0
        else
            echo -e "${RED}✗ $specific_test failed${NC}"
            exit 1
        fi
    else
        # Run all test files
        local test_files=("$TEST_DIR"/test_*.bats)
        
        if [[ ${#test_files[@]} -eq 0 ]]; then
            echo -e "${RED}Error: No test files found in $TEST_DIR${NC}"
            exit 1
        fi
        
        echo -e "${BLUE}Found ${#test_files[@]} test files${NC}"
        echo
        
        # Run each test file
        for test_file in "${test_files[@]}"; do
            if [[ -f "$test_file" ]]; then
                if run_test_file "$test_file" "$verbose"; then
                    passed_tests+=("$(basename "$test_file")")
                else
                    failed_tests+=("$(basename "$test_file")")
                fi
            fi
        done
        
        # Print summary
        echo -e "${BLUE}============================================${NC}"
        echo -e "${BLUE}  Test Summary${NC}"
        echo -e "${BLUE}============================================${NC}"
        echo
        
        if [[ ${#passed_tests[@]} -gt 0 ]]; then
            echo -e "${GREEN}Passed tests (${#passed_tests[@]}):${NC}"
            for test in "${passed_tests[@]}"; do
                echo -e "  ${GREEN}✓ $test${NC}"
            done
            echo
        fi
        
        if [[ ${#failed_tests[@]} -gt 0 ]]; then
            echo -e "${RED}Failed tests (${#failed_tests[@]}):${NC}"
            for test in "${failed_tests[@]}"; do
                echo -e "  ${RED}✗ $test${NC}"
            done
            echo
        fi
        
        local total_tests=$((${#passed_tests[@]} + ${#failed_tests[@]}))
        echo -e "${BLUE}Total: $total_tests tests, ${GREEN}${#passed_tests[@]} passed${NC}, ${RED}${#failed_tests[@]} failed${NC}"
        
        if [[ ${#failed_tests[@]} -gt 0 ]]; then
            exit 1
        else
            echo -e "${GREEN}All tests passed!${NC}"
            exit 0
        fi
    fi
}

# Run main function with all arguments
main "$@"