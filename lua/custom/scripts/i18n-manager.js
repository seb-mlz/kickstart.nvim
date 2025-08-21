#!/usr/bin/env bun
// lua/custom/scripts/i18n-manager.js

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';

class I18nManager {
  constructor(projectRoot = process.cwd()) {
    this.projectRoot = projectRoot;
    this.i18nDir = join(projectRoot, 'i18n', 'lang');
    this.languages = ['fr', 'en'];
    this.ensureDirectoryExists();
  }

  ensureDirectoryExists() {
    if (!existsSync(this.i18nDir)) {
      mkdirSync(this.i18nDir, { recursive: true });
    }
  }

  getFilePath(lang) {
    return join(this.i18nDir, `${lang}.json`);
  }

  readJsonFile(filePath) {
    try {
      if (!existsSync(filePath)) {
        return {};
      }
      const content = readFileSync(filePath, 'utf-8');
      return content.trim() === '' ? {} : JSON.parse(content);
    } catch (error) {
      throw new Error(`Failed to read ${filePath}: ${error.message}`);
    }
  }

  writeJsonFile(filePath, data) {
    try {
      // Ensure directory exists
      const dir = dirname(filePath);
      if (!existsSync(dir)) {
        mkdirSync(dir, { recursive: true });
      }
      
      const jsonString = JSON.stringify(data, null, 2);
      // Ensure Unix line endings and UTF-8 encoding
      writeFileSync(filePath, jsonString + '\n', { encoding: 'utf8' });
    } catch (error) {
      throw new Error(`Failed to write ${filePath}: ${error.message}`);
    }
  }

  // Set nested object property using dot notation
  setNestedProperty(obj, path, value) {
    const keys = path.split('.');
    let current = obj;
    
    for (let i = 0; i < keys.length - 1; i++) {
      const key = keys[i];
      if (!(key in current) || typeof current[key] !== 'object' || Array.isArray(current[key])) {
        current[key] = {};
      }
      current = current[key];
    }
    
    current[keys[keys.length - 1]] = value;
  }

  // Get nested object property using dot notation
  getNestedProperty(obj, path) {
    const keys = path.split('.');
    let current = obj;
    
    for (const key of keys) {
      if (current === null || current === undefined || !(key in current)) {
        return undefined;
      }
      current = current[key];
    }
    
    return current;
  }

  // Check if key exists in any language file
  checkKeyExists(key) {
    for (const lang of this.languages) {
      const filePath = this.getFilePath(lang);
      const data = this.readJsonFile(filePath);
      if (this.getNestedProperty(data, key) !== undefined) {
        return true;
      }
    }
    return false;
  }

  // Add translation key to all language files
  addTranslationKey(key, translations) {
    for (const lang of this.languages) {
      if (!translations[lang]) {
        throw new Error(`Translation for language '${lang}' is required`);
      }
      
      const filePath = this.getFilePath(lang);
      const data = this.readJsonFile(filePath);
      
      // Check if key already exists
      if (this.getNestedProperty(data, key) !== undefined) {
        throw new Error(`Key '${key}' already exists in ${lang}.json`);
      }
      
      this.setNestedProperty(data, key, translations[lang]);
      this.writeJsonFile(filePath, data);
    }
  }

  // Update translation key in all language files
  updateTranslationKey(key, translations) {
    for (const lang of this.languages) {
      if (!translations[lang]) {
        throw new Error(`Translation for language '${lang}' is required`);
      }
      
      const filePath = this.getFilePath(lang);
      const data = this.readJsonFile(filePath);
      
      this.setNestedProperty(data, key, translations[lang]);
      this.writeJsonFile(filePath, data);
    }
  }

  // Get translation key from all language files
  getTranslationKey(key) {
    const result = {};
    for (const lang of this.languages) {
      const filePath = this.getFilePath(lang);
      const data = this.readJsonFile(filePath);
      const value = this.getNestedProperty(data, key);
      if (value !== undefined) {
        result[lang] = value;
      }
    }
    return result;
  }

  // Get all translation keys from all files
  getAllKeys(obj = null, prefix = '', lang = 'en') {
    if (obj === null) {
      const filePath = this.getFilePath(lang);
      obj = this.readJsonFile(filePath);
    }

    const keys = [];
    
    for (const [key, value] of Object.entries(obj)) {
      const fullKey = prefix ? `${prefix}.${key}` : key;
      
      if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
        keys.push(...this.getAllKeys(value, fullKey, lang));
      } else {
        keys.push(fullKey);
      }
    }
    
    return keys;
  }

  // Validate JSON files
  validateJsonFiles() {
    const errors = [];
    
    for (const lang of this.languages) {
      const filePath = this.getFilePath(lang);
      try {
        if (existsSync(filePath)) {
          this.readJsonFile(filePath);
        }
      } catch (error) {
        errors.push(`${lang}.json: ${error.message}`);
      }
    }
    
    return errors;
  }

  // List all keys with their translations
  listAllTranslations() {
    const keys = this.getAllKeys();
    const result = [];
    
    for (const key of keys) {
      const translations = this.getTranslationKey(key);
      let line = `${key}:`;
      for (const lang of this.languages) {
        if (translations[lang]) {
          line += ` ${lang}="${translations[lang]}"`;
        }
      }
      result.push(line);
    }
    
    return result.sort();
  }
}

// CLI Interface
function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.error('Usage: bun i18n-manager.js <action> [arguments]');
    console.error('Actions: add, update, get, check, list, validate');
    process.exit(1);
  }

  const action = args[0];
  let projectRoot = process.cwd();
  
  // Extract project root from arguments
  const rootArg = args.find(arg => arg.startsWith('--root='));
  if (rootArg) {
    projectRoot = rootArg.split('=')[1];
    args.splice(args.indexOf(rootArg), 1);
  }

  const manager = new I18nManager(projectRoot);

  try {
    switch (action) {
      case 'add': {
        const key = args[1];
        const translations = {};
        
        for (let i = 2; i < args.length; i++) {
          if (args[i].includes(':')) {
            const [lang, translation] = args[i].split(':', 2);
            translations[lang] = translation;
          }
        }
        
        manager.addTranslationKey(key, translations);
        console.log('Translation added successfully');
        break;
      }
      
      case 'update': {
        const key = args[1];
        const translations = {};
        
        for (let i = 2; i < args.length; i++) {
          if (args[i].includes(':')) {
            const [lang, translation] = args[i].split(':', 2);
            translations[lang] = translation;
          }
        }
        
        manager.updateTranslationKey(key, translations);
        console.log('Translation updated successfully');
        break;
      }
      
      case 'get': {
        const key = args[1];
        const translations = manager.getTranslationKey(key);
        
        if (Object.keys(translations).length === 0) {
          process.exit(1);
        }
        
        for (const [lang, translation] of Object.entries(translations)) {
          console.log(`${lang}:${translation}`);
        }
        break;
      }
      
      case 'check': {
        const key = args[1];
        const exists = manager.checkKeyExists(key);
        if (exists) {
          console.log('exists');
        }
        process.exit(exists ? 0 : 1);
      }
      
      case 'list': {
        const translations = manager.listAllTranslations();
        translations.forEach(line => console.log(line));
        break;
      }
      
      case 'validate': {
        const errors = manager.validateJsonFiles();
        if (errors.length > 0) {
          errors.forEach(error => console.error(error));
          process.exit(1);
        }
        console.log('All JSON files are valid');
        break;
      }
      
      default:
        console.error(`Unknown action: ${action}`);
        process.exit(1);
    }
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}

if (import.meta.main) {
  main();
}
