#!/bin/bash

# Скрипт сборки и публикации всех приложений портала WeldContour

set -e

echo "🚀 Начинаем сборку портала WeldContour..."

# Сборка каждого приложения
for app in src/*; do
  if [ -d "$app" ]; then
    app_name=$(basename "$app")
    echo "📦 Сборка $app_name..."
    cd "$app"
    flutter clean > /dev/null 2>&1 || true
    flutter pub get > /dev/null 2>&1 || true
    flutter build web --release --base-href "/apps/$app_name/"
    cd ../..
  fi
done

# Копирование собранных файлов в public/apps/
for app in src/*; do
  if [ -d "$app" ]; then
    app_name=$(basename "$app")
    echo "📂 Копирование $app_name в public/apps/$app_name..."
    mkdir -p "public/apps/$app_name"
    rm -rf "public/apps/$app_name"/*
    cp -r "$app/build/web/"* "public/apps/$app_name/" 2>/dev/null || true
  fi
done

echo "✅ Все приложения собраны и скопированы!"

# Git операции
echo "📤 Отправка изменений в ветку gh-pages..."
cd public
git add .
git commit -m "deploy: обновление портала $(date +'%Y-%m-%d %H:%M')" || echo "Нет изменений для коммита"
git push origin gh-pages

echo "🎉 Готово! Сайт: https://weldcontour.github.io/"
