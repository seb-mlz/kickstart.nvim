#!/usr/bin/env bun
// scripts/i18n-add.js

const fs = require('fs');
const path = require('path');

// Get command line arguments
const [, , rootPath, keyPath, frValue, enValue] = process.argv;

if (!rootPath || !keyPath || !frValue || !enValue) {
  console.error('Usage: bun i18n-add.js <root_path> <key_path> <fr_value> <en_value>');
  process.exit(1);
}

// Helper function to set nested key
function setNestedKey(obj, path, value) {
  const keys = path.split('.');
  let current = obj;
  
  for (let i = 0; i < keys.length - 1; i++) {
    const key = keys[i];
    if (!(key in current) || typeof current[key] !== 'object') {
      current[key] = {};
    }
    current = current[key];
  }
  
  current[keys[keys.length - 1]] = value;
}

// Helper function to sort object keys recursively
function sortKeys(obj) {
  if (typeof obj !== 'object' || obj === null || Array.isArray(obj)) {
    return obj;
  }
  
  const sorted = {};
  Object.keys(obj).sort().forEach(key => {
    sorted[key] = sortKeys(obj[key]);
  });
  
  return sorted;
}

try {
  const enPath = path.join(rootPath, 'i18n','lang', 'en.json');
  const frPath = path.join(rootPath, 'i18n','lang', 'fr.json');
  
  // Ensure directory exists
  const dir = path.dirname(enPath);
  fs.mkdirSync(dir, { recursive: true });
  
  // Read or create EN file
  let enData = {};
  if (fs.existsSync(enPath)) {
    const enContent = fs.readFileSync(enPath, 'utf8');
    if (enContent.trim()) {
      enData = JSON.parse(enContent);
    }
  }
  
  // Read or create FR file
  let frData = {};
  if (fs.existsSync(frPath)) {
    const frContent = fs.readFileSync(frPath, 'utf8');
    if (frContent.trim()) {
      frData = JSON.parse(frContent);
    }
  }
  
  // Add new keys
  setNestedKey(enData, keyPath, enValue);
  setNestedKey(frData, keyPath, frValue);
  
  // Sort and write files
  const sortedEnData = sortKeys(enData);
  const sortedFrData = sortKeys(frData);
  
  fs.writeFileSync(enPath, JSON.stringify(sortedEnData, null, 2) + '\n');
  fs.writeFileSync(frPath, JSON.stringify(sortedFrData, null, 2) + '\n');
  
  console.log(`Successfully added i18n key: ${keyPath}`);
} catch (error) {
  console.error(`Error: ${error.message}`);
  process.exit(1);
}
