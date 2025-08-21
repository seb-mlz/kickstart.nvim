#!/usr/bin/env bun
// scripts/i18n-sort.js

const fs = require('fs');
const path = require('path');

// Get command line arguments
const [, , rootPath] = process.argv;

if (!rootPath) {
  console.error('Usage: bun i18n-sort.js <root_path>');
  process.exit(1);
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
  
  let filesProcessed = 0;
  
  // Sort EN file
  if (fs.existsSync(enPath)) {
    const enContent = fs.readFileSync(enPath, 'utf8');
    if (enContent.trim()) {
      const enData = JSON.parse(enContent);
      const sortedEnData = sortKeys(enData);
      fs.writeFileSync(enPath, JSON.stringify(sortedEnData, null, 2) + '\n');
      filesProcessed++;
    }
  }
  
  // Sort FR file
  if (fs.existsSync(frPath)) {
    const frContent = fs.readFileSync(frPath, 'utf8');
    if (frContent.trim()) {
      const frData = JSON.parse(frContent);
      const sortedFrData = sortKeys(frData);
      fs.writeFileSync(frPath, JSON.stringify(sortedFrData, null, 2) + '\n');
      filesProcessed++;
    }
  }
  
  if (filesProcessed > 0) {
    console.log(`Successfully sorted ${filesProcessed} i18n file(s)`);
  } else {
    console.log('No i18n files found to sort');
  }
} catch (error) {
  console.error(`Error: ${error.message}`);
  process.exit(1);
}
