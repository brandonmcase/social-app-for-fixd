#!/bin/bash

# Environment Setup Script for Social App
# This script helps set up the environment variables for the high-concurrency features

echo "Setting up environment for Social App with High-Concurrency Features..."

# Check if .env already exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists. Backing up to .env.backup"
    cp .env .env.backup
fi

# Copy template to .env
if [ -f environment.template ]; then
    cp environment.template .env
    echo "✅ Created .env file from template"
else
    echo "❌ environment.template not found. Please create it first."
    exit 1
fi

# Generate a secure secret key base if not set
if grep -q "your_secret_key_base_here" .env; then
    echo "🔑 Generating secure SECRET_KEY_BASE..."
    SECRET_KEY=$(bundle exec rails secret)
    sed -i.bak "s/your_secret_key_base_here/$SECRET_KEY/" .env
    rm .env.bak
    echo "✅ SECRET_KEY_BASE generated and set"
fi

echo ""
echo "🎉 Environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Review and update .env file with your specific configuration"
echo "2. Make sure PostgreSQL is running"
echo "3. Make sure Redis is running (for production features)"
echo "4. Run: bundle exec rails db:setup"
echo "5. Start the server: bundle exec rails server"
echo ""
echo "For Sidekiq (background jobs):"
echo "  bundle exec sidekiq"
echo ""
echo "For Sidekiq Web UI:"
echo "  Visit http://localhost:3000/sidekiq (admin/password)"
