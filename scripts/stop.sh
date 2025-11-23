#!/bin/bash

# Script to stop and clean up environment

set -e

echo "🛑 Stopping containers..."
docker-compose down

echo ""
echo "🧹 Cleanup complete!"
echo ""
echo "💡 To completely remove volumes (HDFS data), run:"
echo "   docker-compose down -v"
echo ""

