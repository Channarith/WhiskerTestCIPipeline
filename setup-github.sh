#!/bin/bash

# Whisker App - GitHub Setup Script
# For: github.com/Channarith (cvanthin@hotmail.com)

set -e

echo "🚀 Whisker App - GitHub CI/CD Setup"
echo "===================================="
echo ""
echo "GitHub: github.com/Channarith"
echo "Email: cvanthin@hotmail.com"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if we're in a React Native project
if [ ! -f "package.json" ]; then
    print_error "Not in a React Native project directory"
    echo "Please run this from your WhiskerApp directory"
    exit 1
fi

echo "Step 1: Checking Git configuration"
echo "-----------------------------------"

# Check if git is initialized
if [ ! -d ".git" ]; then
    print_warning "Git not initialized"
    read -p "Initialize Git repository? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git init
        print_success "Git initialized"
    else
        print_error "Cannot continue without Git"
        exit 1
    fi
else
    print_success "Git is initialized"
fi

# Check git user configuration
GIT_NAME=$(git config user.name || echo "")
GIT_EMAIL=$(git config user.email || echo "")

if [ -z "$GIT_NAME" ]; then
    print_warning "Git user.name not configured"
    read -p "Enter your name: " USER_NAME
    git config user.name "$USER_NAME"
    print_success "Git user.name set to: $USER_NAME"
else
    print_success "Git user.name: $GIT_NAME"
fi

if [ -z "$GIT_EMAIL" ] || [ "$GIT_EMAIL" != "cvanthin@hotmail.com" ]; then
    print_warning "Git user.email not configured for this project"
    git config user.email "cvanthin@hotmail.com"
    print_success "Git user.email set to: cvanthin@hotmail.com"
else
    print_success "Git user.email: $GIT_EMAIL"
fi

echo ""
echo "Step 2: Setting up .gitignore"
echo "------------------------------"

if [ -f "../.gitignore" ]; then
    print_success ".gitignore already exists"
else
    print_warning ".gitignore not found"
    print_info "A proper .gitignore has been created in the parent directory"
fi

echo ""
echo "Step 3: Checking GitHub CLI"
echo "---------------------------"

if command -v gh >/dev/null 2>&1; then
    print_success "GitHub CLI is installed"
    
    if gh auth status >/dev/null 2>&1; then
        print_success "GitHub CLI is authenticated"
    else
        print_warning "GitHub CLI not authenticated"
        read -p "Authenticate with GitHub now? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh auth login
        fi
    fi
else
    print_warning "GitHub CLI not installed"
    echo ""
    echo "Install with: brew install gh"
    echo "Or create repository manually at: https://github.com/new"
fi

echo ""
echo "Step 4: Initial commit (if needed)"
echo "----------------------------------"

# Check if there are uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    print_info "Found uncommitted changes"
    
    read -p "Create initial commit? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "Initial commit: Whisker app with CI/CD setup"
        print_success "Initial commit created"
    fi
else
    print_success "No uncommitted changes"
fi

echo ""
echo "Step 5: Create GitHub Repository"
echo "---------------------------------"

# Check if remote exists
if git remote get-url origin >/dev/null 2>&1; then
    CURRENT_REMOTE=$(git remote get-url origin)
    print_success "Remote already configured: $CURRENT_REMOTE"
else
    print_warning "No remote configured"
    echo ""
    echo "Options:"
    echo "1. Create repository using GitHub CLI (automatic)"
    echo "2. Create manually and add remote"
    echo ""
    read -p "Choose option (1 or 2): " -n 1 -r
    echo ""
    
    if [ "$REPLY" = "1" ]; then
        if command -v gh >/dev/null 2>&1; then
            read -p "Make repository private? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                gh repo create Whisker --private --source=. --remote=origin
            else
                gh repo create Whisker --public --source=. --remote=origin
            fi
            print_success "Repository created on GitHub"
        else
            print_error "GitHub CLI not available"
            echo "Install with: brew install gh"
            exit 1
        fi
    else
        echo ""
        print_info "Manual setup instructions:"
        echo "1. Go to: https://github.com/new"
        echo "2. Repository name: Whisker"
        echo "3. Choose Private or Public"
        echo "4. DO NOT initialize with README"
        echo "5. Click 'Create repository'"
        echo "6. Then run:"
        echo "   git remote add origin https://github.com/Channarith/Whisker.git"
        echo "   git push -u origin main"
        echo ""
        read -p "Press Enter when done..."
    fi
fi

echo ""
echo "Step 6: Create Branch Structure"
echo "--------------------------------"

# Get current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Ensure we're on main branch
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_info "Switching to main branch"
    git checkout -b main 2>/dev/null || git checkout main
fi

# Create and push branches
for BRANCH in staging develop; do
    if git show-ref --verify --quiet refs/heads/$BRANCH; then
        print_success "Branch '$BRANCH' already exists"
    else
        print_info "Creating branch '$BRANCH'"
        git checkout -b $BRANCH
        git push -u origin $BRANCH 2>/dev/null || print_warning "Could not push $BRANCH (push manually later)"
        git checkout main
        print_success "Branch '$BRANCH' created"
    fi
done

echo ""
echo "Step 7: Push to GitHub"
echo "----------------------"

if git remote get-url origin >/dev/null 2>&1; then
    read -p "Push all branches to GitHub? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push -u origin main 2>/dev/null || print_warning "Main branch might already be pushed"
        git push -u origin staging 2>/dev/null || print_warning "Staging branch might already be pushed"
        git push -u origin develop 2>/dev/null || print_warning "Develop branch might already be pushed"
        print_success "Pushed to GitHub"
    fi
else
    print_warning "No remote configured, skipping push"
fi

echo ""
echo "===================================="
print_success "GitHub repository setup complete!"
echo "===================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Set up GitHub Secrets (REQUIRED for CI/CD):"
echo "   Follow: GITHUB_SETUP.md (Step 5)"
echo ""
echo "2. Configure iOS signing:"
echo "   cd ios && fastlane match init"
echo ""
echo "3. Generate Android keystore:"
echo "   Follow: GITHUB_SETUP.md (Step 5.5)"
echo ""
echo "4. Test the CI/CD pipeline:"
echo "   git checkout develop"
echo "   echo '# Test' >> README.md"
echo "   git commit -am 'test: CI/CD pipeline'"
echo "   git push origin develop"
echo ""
echo "5. Monitor workflow:"
echo "   https://github.com/Channarith/Whisker/actions"
echo ""
echo "📚 Documentation:"
echo "   - Complete guide: GITHUB_SETUP.md"
echo "   - Secrets setup: CI_CD_SECRETS_SETUP.md"
echo "   - Quick reference: QUICK_REFERENCE.md"
echo ""

