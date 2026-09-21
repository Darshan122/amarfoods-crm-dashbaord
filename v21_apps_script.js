/**
 * ============================================================================
 * AMAR FOODS BUYER CRM - FULL 2-WAY SYNC + AUTO-FIX TOOL (V21)
 * Handles:
 *   1. Buyers (Sheet1) - Full 16-Column 2-Way Sync
 *   2. Expos (Expos tab) - Visited Expos & Met Contacts
 *   3. Product Price List (PriceList tab) - Full CRUD (Add, Edit, Delete, Batch)
 *   4. Price History Archive (PriceHistory tab) - Date-Based Upsert (1 Final Price per Date)
 *   5. One-Click Phone #ERROR! Fixer
 *   6. resetPriceListToBaseline() - Wipes PriceList and reloads with official 24 prices
 *   7. renumberAllBuyersSequentially() - Renumbers all Sheet1 Column A sequentially 1..N
 *   8. cleanExistingDuplicatesAndRenumber() - Merges duplicate buyers & renumbers 1..N
 *   9. getOfficial47ProductDirectory() - Official Amar Foods 47 Export Products & HSN Codes
 * ============================================================================
 */

var SPREADSHEET_ID = "1jtqUJxkvQoyxTccC1gOUv1WejJigm7DMX9P66OyrhuA";

// ═══════════════════════════════════════════════════════════════════════════
// OFFICIAL BASELINE: 24 PRODUCTS (Amar Foods – 09 Sep 2026)
// ═══════════════════════════════════════════════════════════════════════════

function getBaseline24Products(todayStr) {
  return [
    // ─── WHITE ONION ─────────────────────────────────────────────────────
    ["WO-01", "White Onion", "White Onion Flakes (Sorted)",   "A-Grade (Optical Sorted)",       "14 kg Bag", "₹ / kg", 197, 197, "1000 kg", "Daily Spot Rate", "Export Quality, Optical Sorted",  todayStr],
    ["WO-02", "White Onion", "White Onion Flakes (Unsorted)", "Commercial / Domestic Grade",     "14 kg Bag", "₹ / kg", 185, 185, "1000 kg", "Daily Spot Rate", "Commercial / Domestic Grade",      todayStr],
    ["WO-03", "White Onion", "White Onion Chopped",           "3 - 5 mm (Export Quality)",       "20 kg Bag", "₹ / kg", 197, 197, "1000 kg", "Daily Spot Rate", "Clean & Even Cut",                 todayStr],
    ["WO-04", "White Onion", "White Onion Minced",            "1 - 3 mm (Export Quality)",       "20 kg Bag", "₹ / kg", 197, 197, "1000 kg", "Daily Spot Rate", "Standard Size",                    todayStr],
    ["WO-05", "White Onion", "White Onion Granules",          "40 - 60 Mesh (Export Quality)",   "25 kg Bag", "₹ / kg", 187, 187, "1000 kg", "Daily Spot Rate", "Free Flowing",                     todayStr],
    ["WO-06", "White Onion", "White Onion Powder",            "80 - 100 Mesh (Export Quality)",  "25 kg Bag", "₹ / kg", 172, 172, "1000 kg", "Daily Spot Rate", "100% Pure & Fine",                 todayStr],
    // ─── RED ONION ───────────────────────────────────────────────────────
    ["RO-01", "Red Onion",   "Red Onion Flakes (Sorted)",     "A-Grade (Optical Sorted)",       "14 kg Bag", "₹ / kg", 137, 137, "1000 kg", "Daily Spot Rate", "Export Quality, Optical Sorted",  todayStr],
    ["RO-02", "Red Onion",   "Red Onion Flakes (Unsorted)",   "Commercial / Domestic Grade",     "14 kg Bag", "₹ / kg", 115, 115, "1000 kg", "Daily Spot Rate", "Commercial / Domestic Grade",      todayStr],
    ["RO-03", "Red Onion",   "Red Onion Chopped",             "3 - 5 mm (Export Quality)",       "20 kg Bag", "₹ / kg", 140, 140, "1000 kg", "Daily Spot Rate", "Clean & Even Cut",                 todayStr],
    ["RO-04", "Red Onion",   "Red Onion Minced",              "1 - 3 mm (Export Quality)",       "20 kg Bag", "₹ / kg", 140, 140, "1000 kg", "Daily Spot Rate", "Uniform Size",                     todayStr],
    ["RO-05", "Red Onion",   "Red Onion Granules",            "40 - 60 Mesh (Export Quality)",   "25 kg Bag", "₹ / kg", 122, 122, "1000 kg", "Daily Spot Rate", "Free Flowing",                     todayStr],
    ["RO-06", "Red Onion",   "Red Onion Powder",              "80 - 100 Mesh (Export Quality)",  "25 kg Bag", "₹ / kg", 112, 112, "1000 kg", "Daily Spot Rate", "Deep Red Pure Powder",             todayStr],
    // ─── PINK ONION ──────────────────────────────────────────────────────
    ["PO-01", "Pink Onion",  "Pink Onion Flakes (Sorted)",    "A-Grade (Optical Sorted)",       "14 kg Bag", "₹ / kg", 132, 132, "1000 kg", "Daily Spot Rate", "Export Quality, Optical Sorted",  todayStr],
    ["PO-02", "Pink Onion",  "Pink Onion Flakes (Unsorted)",  "Commercial / Domestic Grade",     "14 kg Bag", "₹ / kg", 122, 122, "1000 kg", "Daily Spot Rate", "Commercial / Domestic Grade",      todayStr],
    ["PO-03", "Pink Onion",  "Pink Onion Chopped",            "3 - 5 mm (Export Quality)",       "20 kg Bag", "₹ / kg", 127, 127, "1000 kg", "Daily Spot Rate", "Clean & Even Cut",                 todayStr],
    ["PO-04", "Pink Onion",  "Pink Onion Minced",             "1 - 3 mm (Export Quality)",       "20 kg Bag", "₹ / kg", 127, 127, "1000 kg", "Daily Spot Rate", "Uniform Cut",                      todayStr],
    ["PO-05", "Pink Onion",  "Pink Onion Granules",           "40 - 60 Mesh (Export Quality)",   "25 kg Bag", "₹ / kg", 132, 132, "1000 kg", "Daily Spot Rate", "Free Flowing",                     todayStr],
    ["PO-06", "Pink Onion",  "Pink Onion Powder",             "80 - 100 Mesh (Export Quality)",  "25 kg Bag", "₹ / kg", 112, 112, "1000 kg", "Daily Spot Rate", "100% Pure Pink Onion",             todayStr],
    // ─── GARLIC ──────────────────────────────────────────────────────────
    ["GA-01", "Garlic",      "Garlic Flakes (Sorted)",        "A-Grade (Machine Sorted)",        "25 kg Bag", "₹ / kg", 217, 217, "1000 kg", "Daily Spot Rate", "Export Quality, Machine Sorted",   todayStr],
    ["GA-02", "Garlic",      "Garlic Flakes (Unsorted)",      "Commercial / Domestic Grade",     "25 kg Bag", "₹ / kg", 187, 187, "1000 kg", "Daily Spot Rate", "Commercial / Domestic Grade",      todayStr],
    ["GA-03", "Garlic",      "Garlic Chopped",                "3 - 5 mm (Export Quality)",       "25 kg Bag", "₹ / kg", 237, 237, "1000 kg", "Daily Spot Rate", "Even Granulation",                 todayStr],
    ["GA-04", "Garlic",      "Garlic Minced",                 "1 - 3 mm (Export Quality)",       "25 kg Bag", "₹ / kg", 237, 237, "1000 kg", "Daily Spot Rate", "Clean & Aromatic",                 todayStr],
    ["GA-05", "Garlic",      "Garlic Granules",               "40 - 60 Mesh (Export Quality)",   "25 kg Bag", "₹ / kg", 232, 232, "1000 kg", "Daily Spot Rate", "Golden/White Free Flowing",        todayStr],
    ["GA-06", "Garlic",      "Garlic Powder",                 "100 Mesh (Export Quality)",       "25 kg Bag", "₹ / kg", 110, 110, "1000 kg", "Daily Spot Rate", "Pure Aromatic Flavor",             todayStr]
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔄 ONE-CLICK RESET: Wipe PriceList + PriceHistory and reload 24 baseline
// Run this ONCE from Apps Script editor > Run > resetPriceListToBaseline
// ═══════════════════════════════════════════════════════════════════════════

function resetPriceListToBaseline() {
  var ss = getSpreadsheet();
  if (!ss) { Logger.log("ERROR: Could not open spreadsheet"); return; }

  var todayStr = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd");

  // ── Wipe and rebuild PriceList ──────────────────────────────────────────
  var priceSheet = ss.getSheetByName("PriceList");
  if (priceSheet) {
    priceSheet.clearContents();
  } else {
    priceSheet = ss.insertSheet("PriceList");
  }

  var headers = [
    "Product ID", "Category", "Product Name", "Grade / Spec", "Packing",
    "Currency", "Current Ex-Factory Rate", "Prev Rate", "MOQ",
    "Validity", "Remarks", "Last Updated"
  ];
  priceSheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  priceSheet.getRange(1, 1, 1, headers.length)
    .setFontWeight("bold")
    .setBackground("#0F766E")
    .setFontColor("#FFFFFF");
  priceSheet.setFrozenRows(1);
  for (var c = 1; c <= headers.length; c++) {
    priceSheet.setColumnWidth(c, 140);
  }

  var products = getBaseline24Products(todayStr);
  priceSheet.getRange(2, 1, products.length, headers.length).setValues(products);

  // ── Wipe PriceHistory ──────────────────────────────────────────────────
  var histSheet = ss.getSheetByName("PriceHistory");
  if (histSheet) {
    histSheet.clearContents();
    var histHeaders = [
      "History ID", "Week / Validity", "Product ID", "Category", "Product Name",
      "Grade / Spec", "Packing", "Currency", "Price", "Change Amount",
      "Change %", "Recorded Date"
    ];
    histSheet.getRange(1, 1, 1, histHeaders.length).setValues([histHeaders]);
    histSheet.getRange(1, 1, 1, histHeaders.length)
      .setFontWeight("bold")
      .setBackground("#1E3A8A")
      .setFontColor("#FFFFFF");
    histSheet.setFrozenRows(1);
    for (var hc = 1; hc <= histHeaders.length; hc++) {
      histSheet.setColumnWidth(hc, 130);
    }
  }

  Logger.log("✅ PriceList reset to 24 official baseline products. PriceHistory cleared.");
  Logger.log("   First product: WO-01 White Onion Flakes (Sorted) = ₹197/kg");
}

// ═══════════════════════════════════════════════════════════════════════════
// 🛠️ ONE-CLICK TOOL: FIX ALL EXISTING PHONE #ERROR! CELLS IN SHEET
// ═══════════════════════════════════════════════════════════════════════════

function fixAllPhoneErrors() {
  var ss = getSpreadsheet();
  if (!ss) return;

  var fixedCount = 0;
  var sheetNames = ["Sheet1", "Expos"];

  for (var s = 0; s < sheetNames.length; s++) {
    var sheet = ss.getSheetByName(sheetNames[s]);
    if (!sheet) continue;

    var lastRow = sheet.getLastRow();
    if (lastRow <= 1) continue;

    var phoneCol = (sheetNames[s] === "Sheet1") ? 5 : 11;
    sheet.getRange(2, phoneCol, lastRow - 1, 1).setNumberFormat("@");

    var range = sheet.getRange(2, phoneCol, lastRow - 1, 1);
    var formulas = range.getFormulas();
    var values = range.getValues();

    for (var i = 0; i < values.length; i++) {
      var formula = String(formulas[i][0] || '').trim();
      var val = String(values[i][0] || '').trim();

      if (formula && (formula.indexOf('=+') === 0 || formula.indexOf('=') === 0 || formula.indexOf('+') === 0)) {
        var cleanPhone = formula.replace(/^=\+?/, '+').replace(/^=/, '');
        sheet.getRange(i + 2, phoneCol).setValue("'" + cleanPhone);
        fixedCount++;
      } else if (val && (val.indexOf('#ERROR') === 0 || val.indexOf('#') === 0)) {
        if (formula) {
          var cleanFromFormula = formula.replace(/^=\+?/, '+').replace(/^=/, '');
          sheet.getRange(i + 2, phoneCol).setValue("'" + cleanFromFormula);
        } else {
          sheet.getRange(i + 2, phoneCol).setValue("");
        }
        fixedCount++;
      } else if (val && val.charAt(0) === '+') {
        sheet.getRange(i + 2, phoneCol).setValue("'" + val);
        fixedCount++;
      }
    }
  }

  Logger.log("✅ Successfully fixed " + fixedCount + " phone number cells!");
}

// ═══════════════════════════════════════════════════════════════════════════
// WEB APP API (doGet & doPost)
// ═══════════════════════════════════════════════════════════════════════════


// ═══════════════════════════════════════════════════════════════════════════
// OFFICIAL AMAR FOODS 47 EXPORT PRODUCTS DIRECTORY (WITH HSN CODES)
// ═══════════════════════════════════════════════════════════════════════════

function getOfficial47ProductDirectory() {
  return [
    { id: "WO-01", category: "Dehydrated White Onion", name: "White Onion Flakes (Sorted)", hsnCode: "07122000", spec: "A-Grade (Optical Sorted)", packing: "14 kg Poly-lined Bag" },
    { id: "WO-02", category: "Dehydrated White Onion", name: "White Onion Flakes (Unsorted)", hsnCode: "07122000", spec: "Commercial / Domestic Grade", packing: "14 kg Poly-lined Bag" },
    { id: "WO-03", category: "Dehydrated White Onion", name: "White Onion Chopped", hsnCode: "07122000", spec: "3 - 5 mm (Export Quality)", packing: "20 kg Poly-lined Bag" },
    { id: "WO-04", category: "Dehydrated White Onion", name: "White Onion Minced", hsnCode: "07122000", spec: "1 - 3 mm (Export Quality)", packing: "20 kg Poly-lined Bag" },
    { id: "WO-05", category: "Dehydrated White Onion", name: "White Onion Granules", hsnCode: "07122000", spec: "40 - 60 Mesh (Export Quality)", packing: "25 kg Paper/Poly Bag" },
    { id: "WO-06", category: "Dehydrated White Onion", name: "White Onion Powder", hsnCode: "07122000", spec: "80 - 100 Mesh (Export Quality)", packing: "25 kg Poly-lined Bag" },

    { id: "RO-01", category: "Dehydrated Red Onion", name: "Red Onion Flakes (Sorted)", hsnCode: "07122000", spec: "A-Grade (Optical Sorted)", packing: "14 kg Poly-lined Bag" },
    { id: "RO-02", category: "Dehydrated Red Onion", name: "Red Onion Flakes (Unsorted)", hsnCode: "07122000", spec: "Commercial / Domestic Grade", packing: "14 kg Poly-lined Bag" },
    { id: "RO-03", category: "Dehydrated Red Onion", name: "Red Onion Chopped", hsnCode: "07122000", spec: "3 - 5 mm (Export Quality)", packing: "20 kg Poly-lined Bag" },
    { id: "RO-04", category: "Dehydrated Red Onion", name: "Red Onion Minced", hsnCode: "07122000", spec: "1 - 3 mm (Export Quality)", packing: "20 kg Poly-lined Bag" },
    { id: "RO-05", category: "Dehydrated Red Onion", name: "Red Onion Granules", hsnCode: "07122000", spec: "40 - 60 Mesh (Export Quality)", packing: "25 kg Paper/Poly Bag" },
    { id: "RO-06", category: "Dehydrated Red Onion", name: "Red Onion Powder", hsnCode: "07122000", spec: "80 - 100 Mesh (Export Quality)", packing: "25 kg Poly-lined Bag" },

    { id: "PO-01", category: "Dehydrated Pink Onion", name: "Pink Onion Flakes (Sorted)", hsnCode: "07122000", spec: "A-Grade (Optical Sorted)", packing: "14 kg Poly-lined Bag" },
    { id: "PO-02", category: "Dehydrated Pink Onion", name: "Pink Onion Flakes (Unsorted)", hsnCode: "07122000", spec: "Commercial / Domestic Grade", packing: "14 kg Poly-lined Bag" },
    { id: "PO-03", category: "Dehydrated Pink Onion", name: "Pink Onion Chopped", hsnCode: "07122000", spec: "3 - 5 mm (Export Quality)", packing: "20 kg Poly-lined Bag" },
    { id: "PO-04", category: "Dehydrated Pink Onion", name: "Pink Onion Minced", hsnCode: "07122000", spec: "1 - 3 mm (Export Quality)", packing: "20 kg Poly-lined Bag" },
    { id: "PO-05", category: "Dehydrated Pink Onion", name: "Pink Onion Granules", hsnCode: "07122000", spec: "40 - 60 Mesh (Export Quality)", packing: "25 kg Paper/Poly Bag" },
    { id: "PO-06", category: "Dehydrated Pink Onion", name: "Pink Onion Powder", hsnCode: "07122000", spec: "80 - 100 Mesh (Export Quality)", packing: "25 kg Poly-lined Bag" },

    { id: "GA-01", category: "Dehydrated Garlic", name: "Garlic Flakes (Sorted)", hsnCode: "07129020", spec: "A-Grade (Machine Sorted)", packing: "25 kg Poly-lined Bag" },
    { id: "GA-02", category: "Dehydrated Garlic", name: "Garlic Flakes (Unsorted)", hsnCode: "07129020", spec: "Commercial / Domestic Grade", packing: "25 kg Poly-lined Bag" },
    { id: "GA-03", category: "Dehydrated Garlic", name: "Garlic Chopped", hsnCode: "07129020", spec: "3 - 5 mm (Export Quality)", packing: "25 kg Poly-lined Bag" },
    { id: "GA-04", category: "Dehydrated Garlic", name: "Garlic Minced", hsnCode: "07129020", spec: "1 - 3 mm (Export Quality)", packing: "25 kg Poly-lined Bag" },
    { id: "GA-05", category: "Dehydrated Garlic", name: "Garlic Granules", hsnCode: "07129020", spec: "40 - 60 Mesh (Export Quality)", packing: "25 kg Paper/Poly Bag" },
    { id: "GA-06", category: "Dehydrated Garlic", name: "Garlic Powder", hsnCode: "07129020", spec: "100 Mesh (Export Quality)", packing: "25 kg Poly-lined Bag" },

    { id: "BG-01", category: "Black Garlic", name: "Black Garlic Cloves", hsnCode: "07129020", spec: "Aged / Fermented 90 Days", packing: "5 kg / 10 kg Carton" },
    { id: "BG-02", category: "Black Garlic", name: "Black Garlic Powder", hsnCode: "07129020", spec: "100 Mesh Pure Fermented", packing: "20 kg Drum" },

    { id: "GI-01", category: "Pure Ginger", name: "Ginger Flakes / Slices", hsnCode: "09101110", spec: "Solar Dried, High Zingiberene", packing: "20 kg Bag" },
    { id: "GI-02", category: "Pure Ginger", name: "Ginger Powder", hsnCode: "09101210", spec: "100% Pure, Unadulterated", packing: "25 kg Bag" },

    { id: "BT-01", category: "Vegetables & Powders", name: "Beetroot Powder", hsnCode: "07129090", spec: "100% Natural Spray/Air Dried", packing: "25 kg Bag" },
    { id: "CR-01", category: "Vegetables & Powders", name: "Carrot Flakes & Powder", hsnCode: "07129090", spec: "Dehydrated Orange Carrot", packing: "20 kg Bag" },
    { id: "SP-01", category: "Vegetables & Powders", name: "Sweet Potato Flakes & Powder", hsnCode: "07142000", spec: "Clean Dried Sweet Potato", packing: "25 kg Bag" },

    { id: "MO-01", category: "Greens & Herbs", name: "Moringa Leaf Powder", hsnCode: "12119099", spec: "Organic / Natural Superfood", packing: "20 kg Bag" },
    { id: "SN-01", category: "Greens & Herbs", name: "Spinach Powder (Palak)", hsnCode: "07129090", spec: "Air-Dried Green Leaf Powder", packing: "20 kg Bag" },
    { id: "MT-01", category: "Greens & Herbs", name: "Mint Leaves Flakes & Powder (Pudina)", hsnCode: "12119099", spec: "Pure Mentha Aromatic Cut", packing: "15 kg Bag" },
    { id: "CL-01", category: "Greens & Herbs", name: "Cilantro / Coriander Leaves Flakes & Powder", hsnCode: "07129090", spec: "Dried Green Dhaniya Leaves", packing: "15 kg Bag" },
    { id: "CY-01", category: "Greens & Herbs", name: "Curry Leaf Flakes & Powder (Kadi Patta)", hsnCode: "12119099", spec: "Crisp Dried South Indian Leaves", packing: "15 kg Bag" },
    { id: "KM-01", category: "Greens & Herbs", name: "Kasuri Methi (Fenugreek Leaves)", hsnCode: "07129090", spec: "Nagauri Green Clean Sort", packing: "10 kg / 15 kg Carton" },

    { id: "GC-01", category: "Chillies & Savory", name: "Green Chilli Flakes & Powder", hsnCode: "07129090", spec: "High Pungency Green Chilli", packing: "20 kg Bag" },
    { id: "RC-01", category: "Chillies & Savory", name: "Red Chilli Flakes (Crushed)", hsnCode: "09042110", spec: "Stemless Pizza/Pasta Flakes", packing: "20 kg Bag" },
    { id: "RC-02", category: "Chillies & Savory", name: "Red Chilli Powder", hsnCode: "09042210", spec: "Bright Red, Pure Capsicum", packing: "25 kg Bag" },
    { id: "AM-01", category: "Chillies & Savory", name: "Amchur Powder (Dry Mango Powder)", hsnCode: "08045090", spec: "Desi Tart Raw Mango", packing: "25 kg Bag" },
    { id: "TM-01", category: "Chillies & Savory", name: "Tomato Powder", hsnCode: "20029000", spec: "100% Spray Dried Red Ripe", packing: "20 kg Bag" },
    { id: "LM-01", category: "Chillies & Savory", name: "Lemon Powder", hsnCode: "08055000", spec: "Pure Citrus Limon Tart", packing: "20 kg Drum" },
    { id: "TR-01", category: "Chillies & Savory", name: "Tamarind Powder (Imli)", hsnCode: "08134090", spec: "De-seeded Pure Tamarind Pulp", packing: "25 kg Bag" },

    { id: "CM-01", category: "Spices & Specialty", name: "Cumin Powder (Jeera)", hsnCode: "09093200", spec: "Unadulterated Ground Cumin", packing: "25 kg Bag" },
    { id: "CD-01", category: "Spices & Specialty", name: "Coriander Powder (Dhania)", hsnCode: "09092200", spec: "Fresh Aromatic Ground Seed", packing: "25 kg Bag" },
    { id: "TU-01", category: "Spices & Specialty", name: "Turmeric Powder", hsnCode: "09103020", spec: "High Curcumin (>3%) Golden Sort", packing: "25 kg Bag" },
    { id: "FO-01", category: "Spices & Specialty", name: "Crispy Fried Onion", hsnCode: "20059900", spec: "Biryani & Burger Golden Topping", packing: "10 kg Carton / Pouch" },
    { id: "TO-01", category: "Spices & Specialty", name: "Toasted Onion Flakes", hsnCode: "07122000", spec: "Roasted Golden Dehydrated Onion", packing: "14 kg Bag" },
    { id: "SS-01", category: "Spices & Specialty", name: "Sesame Seeds", hsnCode: "12074090", spec: "Natural & Hulled White/Black Sort", packing: "25 kg Bag" }
  ];
}

function doGet(e) {
  try {
    var action = (e && e.parameter && e.parameter.action) ? e.parameter.action : "getBuyers";

    // ─── 1. BUYER ACTIONS ──────────────────────────────────────────────
    if (action === "cleanDuplicates" || action === "deduplicateBuyers") {
      var cleanRes = cleanExistingDuplicatesAndRenumber();
      return jsonResponse({ status: "success", result: cleanRes });
    }
    if (action === "renumberBuyers") {
      var count = renumberAllBuyersSequentially();
      return jsonResponse({ status: "success", count: count });
    }
    if (action === "getBuyers") {
      return jsonResponse({ status: "success", buyers: getAllBuyers() });
    }
    if (action === "updateBuyer" && e.parameter.payload) {
      var buyer = decodePayload(e.parameter.payload);
      return jsonResponse({ status: "success", result: upsertBuyer(buyer) });
    }
    if (action === "deleteBuyer" && e.parameter.id) {
      return jsonResponse({ status: "success", result: deleteBuyer(e.parameter.id) });
    }

    // ─── 2. EXPO ACTIONS ───────────────────────────────────────────────
    if (action === "getExpos") {
      return jsonResponse({ status: "success", expos: getAllExpos() });
    }
    if (action === "updateExpo" && e.parameter.payload) {
      var expo = decodePayload(e.parameter.payload);
      return jsonResponse({ status: "success", result: upsertExpo(expo) });
    }
    if (action === "deleteExpo" && e.parameter.id) {
      return jsonResponse({ status: "success", result: deleteExpo(e.parameter.id) });
    }

    // ─── 3. PRODUCT PRICE LIST & HISTORY ACTIONS ───────────────────────
    if (action === "getPrices") {
      return jsonResponse({ status: "success", prices: getAllPrices() });
    }
    if (action === "getPriceHistory") {
      return jsonResponse({ status: "success", history: getAllPriceHistory() });
    }
    if (action === "saveProductPrice") {
      var payload = e.parameter.payload ? decodePayload(e.parameter.payload) : e.parameter;
      var priceItem = payload.price || payload;
      var weekLabel = payload.weekLabel || "Daily Spot Rate";
      return jsonResponse({ status: "success", result: upsertProductPrice(priceItem, weekLabel) });
    }
    if (action === "deleteProductPrice" && e.parameter.id) {
      return jsonResponse({ status: "success", result: deleteProductPrice(e.parameter.id) });
    }
    if (action === "updatePrices" && e.parameter.payload) {
      var pricePayload = decodePayload(e.parameter.payload);
      return jsonResponse({ status: "success", result: saveWeeklyPrices(pricePayload) });
    }

        // ─── 4. OFFICIAL 47 PRODUCT CATALOG DIRECTORY ──────────────────────
    if (action === "getProductCatalog" || action === "getCatalog47") {
      return jsonResponse({ status: "success", catalog: getOfficial47ProductDirectory() });
    }

    return jsonResponse({ status: "error", message: "Invalid action: " + action });
  } catch (err) {
    return jsonResponse({ status: "error", error: err.toString() });
  }
}

function doPost(e) {
  try {
    var rawText = (e && e.postData && e.postData.contents) ? e.postData.contents : "{}";
    var contents = JSON.parse(rawText);
    var action = contents.action || (e && e.parameter && e.parameter.action);

    // ─── 1. BUYER ACTIONS ──────────────────────────────────────────────
    if (action === "cleanDuplicates" || action === "deduplicateBuyers") {
      var cleanRes = cleanExistingDuplicatesAndRenumber();
      return jsonResponse({ status: "success", result: cleanRes });
    }
    if (action === "renumberBuyers") {
      var count = renumberAllBuyersSequentially();
      return jsonResponse({ status: "success", count: count });
    }
    if (action === "updateBuyer" || action === "saveBuyer") {
      var buyerData = contents.buyer || contents;
      return jsonResponse({ status: "success", result: upsertBuyer(buyerData) });
    }
    if (action === "batchUpdateBuyers" && Array.isArray(contents.buyers)) {
      for (var bIdx = 0; bIdx < contents.buyers.length; bIdx++) {
        upsertBuyer(contents.buyers[bIdx]);
      }
      return jsonResponse({ status: "success", count: contents.buyers.length });
    }
    if (action === "deleteBuyer") {
      var deleteId = contents.id || contents.srNo || (e && e.parameter && e.parameter.id);
      return jsonResponse({ status: "success", result: deleteBuyer(deleteId) });
    }

    // ─── 2. EXPO ACTIONS ───────────────────────────────────────────────
    if (action === "updateExpo" || action === "saveExpo") {
      var expoData = contents.expo || contents;
      return jsonResponse({ status: "success", result: upsertExpo(expoData) });
    }
    if (action === "deleteExpo") {
      var expoDeleteId = contents.id || (e && e.parameter && e.parameter.id);
      return jsonResponse({ status: "success", result: deleteExpo(expoDeleteId) });
    }

    // ─── 3. PRODUCT PRICE LIST & HISTORY ACTIONS ───────────────────────
    if (action === "saveProductPrice") {
      var priceItem = contents.price || contents;
      var wkLabel = contents.weekLabel || "Daily Spot Rate";
      return jsonResponse({ status: "success", result: upsertProductPrice(priceItem, wkLabel) });
    }
    if (action === "deleteProductPrice") {
      var pDeleteId = contents.id || contents.productId || (e && e.parameter && e.parameter.id);
      return jsonResponse({ status: "success", result: deleteProductPrice(pDeleteId) });
    }
    if (action === "updatePrices" || action === "saveWeeklyPrices") {
      return jsonResponse({ status: "success", result: saveWeeklyPrices(contents) });
    }

        // ─── 4. OFFICIAL 47 PRODUCT CATALOG DIRECTORY ──────────────────────
    if (action === "getProductCatalog" || action === "getCatalog47") {
      return jsonResponse({ status: "success", catalog: getOfficial47ProductDirectory() });
    }

    return jsonResponse({ status: "error", message: "Unknown action: " + action });
  } catch (err) {
    return jsonResponse({ status: "error", error: err.toString() });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

function jsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

function decodePayload(payloadParam) {
  var str = String(payloadParam).trim();
  if (str.charAt(0) === "{" || str.charAt(0) === "[") {
    return JSON.parse(str);
  }
  var clean = str
    .replace(/ /g, "+")
    .replace(/-/g, "+")
    .replace(/_/g, "/");
  while (clean.length % 4 !== 0) { clean += "="; }
  var raw = Utilities.newBlob(Utilities.base64Decode(clean)).getDataAsString(Utilities.Charset.UTF_8);
  return JSON.parse(raw);
}

function getSpreadsheet() {
  try { return SpreadsheetApp.getActiveSpreadsheet(); } catch(e) {}
  try { return SpreadsheetApp.openById(SPREADSHEET_ID); } catch(e) {}
  return null;
}

function getBuyersSheet() {
  var ss = getSpreadsheet();
  if (!ss) return null;
  return ss.getSheetByName("Sheet1") || ss.getSheets()[0];
}

function formatDate(val) {
  if (!val) return "";
  if (val instanceof Date) {
    return Utilities.formatDate(val, Session.getScriptTimeZone(), "yyyy-MM-dd");
  }
  return String(val).trim();
}

function cleanPhoneForRead(raw) {
  var s = String(raw || '').trim();
  if (s.indexOf("'") === 0) s = s.substring(1).trim();
  var lower = s.toLowerCase();
  if (lower === "#error!" || lower.indexOf("#error") === 0 || lower === "#ref!" || lower === "#value!" || lower === "#n/a" || lower === "n/a" || lower === "-" || lower === "null") {
    return "";
  }
  return s;
}

function formatPhoneForWrite(raw) {
  var s = String(raw || '').trim();
  if (s.indexOf("'") === 0) s = s.substring(1).trim();
  if (!s) return "";
  if (s.charAt(0) === '+' || s.charAt(0) === '=') {
    return "'" + s;
  }
  return s;
}

function getTrueLastRow(sheet) {
  var lastRow = sheet.getLastRow();
  if (lastRow <= 1) return 1;
  var data = sheet.getRange("B1:B" + lastRow).getValues();
  for (var i = data.length - 1; i >= 0; i--) {
    if (String(data[i][0]).trim() !== "") return i + 1;
  }
  return 1;
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. BUYERS (Sheet1) – Full 16-Column CRUD
// ═══════════════════════════════════════════════════════════════════════════

function getAllBuyers() {
  var sheet = getBuyersSheet();
  if (!sheet) return [];
  var data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  // Check if Sr. No. sequence in Column A has any gaps or duplicate numbers
  var needsRenumber = false;
  var seenSrNos = {};
  var validRowCount = 0;
  for (var r = 1; r < data.length; r++) {
    var rComp = String(data[r][1] || '').trim();
    var rWeb  = String(data[r][2] || '').trim();
    var rMail = String(data[r][3] || '').trim();
    if ((!rComp || rComp.toLowerCase()==='n/a' || rComp==='-') &&
        (!rWeb  || rWeb.toLowerCase()==='n/a'  || rWeb==='-') &&
        (!rMail || rMail.toLowerCase()==='n/a' || rMail==='-')) continue;

    validRowCount++;
    var rawNum = String(data[r][0] || '').replace('AF-', '').replace(/^0+/, '').trim();
    if (rawNum !== String(validRowCount) || seenSrNos[rawNum]) {
      needsRenumber = true;
    }
    seenSrNos[rawNum] = true;
  }

  if (needsRenumber) {
    renumberAllBuyersSequentially();
    data = sheet.getDataRange().getValues(); // refresh
  }

  var buyers = [];
  for (var i = 1; i < data.length; i++) {
    var row = data[i];
    var company = String(row[1] || '').trim();
    var website = String(row[2] || '').trim();
    var email   = String(row[3] || '').trim();

    if ((!company || company.toLowerCase()==='n/a' || company==='-') &&
        (!website || website.toLowerCase()==='n/a' || website==='-') &&
        (!email   || email.toLowerCase()==='n/a'   || email==='-')) continue;

    var srNoRaw = String(row[0] || '').replace('AF-', '').replace(/^0+/, '').trim();
    var srNo = parseInt(srNoRaw) || (buyers.length + 1);

    var firstEmail = formatDate(row[7]);
    var clientReply = String(row[9] || 'Pending').trim();
    var status = String(row[12] || '').trim();
    if (!status) {
      status = clientReply === "Yes" ? "Converted" : (clientReply === "Hold" ? "On Hold" : (firstEmail ? "First Email Sent" : "New"));
    }

    buyers.push({
      "ID": "AF-" + String(srNo).padStart(5, '0'),
      "SR_NO": String(srNo),
      "Sr. No.": String(srNo),
      "Importer Company": company || ('Importer #' + srNo),
      "Importer Website": website,
      "Email": email,
      "Phone": cleanPhoneForRead(row[4]),
      "Connection Method": String(row[5] || 'Email').trim(),
      "Connection Date": formatDate(row[6]),
      "First Email Date": firstEmail,
      "Follow Up Date": formatDate(row[8]),
      "Client Reply": clientReply,
      "Last Email Date": formatDate(row[10]) || firstEmail,
      "Follow-Up Count": String(row[11] || (firstEmail ? "1" : "0")),
      "Current Status": status,
      "Next Action": String(row[13] || "Follow-Up").trim(),
      "Notes": String(row[14] || '').trim(),
      "Market Type": String(row[15] || 'International').trim()
    });
  }
  return buyers;
}

function upsertBuyer(buyer) {
  var sheet = getBuyersSheet();
  if (!sheet) return false;
  var data = sheet.getDataRange().getValues();

  var targetSrNo = String(buyer["Sr. No."] || buyer.srNo || buyer.SR_NO || buyer.ID || '')
    .replace('AF-', '').replace(/^0+/, '').trim();
  var inputCompany = String(buyer["Importer Company"] || buyer.company || '').trim();
  var inputEmail = String(buyer["Email"] || buyer.email || '').trim();
  var inputWebsite = String(buyer["Importer Website"] || buyer.website || '').trim();
  var inputPhone = String(buyer["Phone"] || buyer.phone || '').trim();

  var normInputComp = normalizeCompanyName(inputCompany);
  var inputDomain = extractDomain(inputWebsite);
  var inputEmails = extractEmailsList(inputEmail);
  var inputPhoneDigits = cleanPhoneDigits(inputPhone);

  var rowIndex = -1;

  // 1. Match by numeric Sr. No. if editing existing row
  if (targetSrNo && parseInt(targetSrNo) > 0) {
    for (var i = 1; i < data.length; i++) {
      var cellVal = String(data[i][0] || '').replace('AF-', '').replace(/^0+/, '').trim();
      if (cellVal === targetSrNo) {
        rowIndex = i + 1;
        break;
      }
    }
  }

  // 2. If not matched by Sr. No., check for duplicates by Company Name, Email, Website Domain, or Phone
  if (rowIndex < 0) {
    for (var j = 1; j < data.length; j++) {
      var row = data[j];
      var rowComp = normalizeCompanyName(row[1]);
      var rowWeb = extractDomain(row[2]);
      var rowEmails = extractEmailsList(row[3]);
      var rowPhoneDigits = cleanPhoneDigits(row[4]);

      // Normalized company match
      var compMatch = (normInputComp.length >= 3 && rowComp.length >= 3 && normInputComp === rowComp);

      // Email address match
      var emailMatch = false;
      for (var e = 0; e < inputEmails.length; e++) {
        if (rowEmails.indexOf(inputEmails[e]) !== -1) {
          emailMatch = true;
          break;
        }
      }

      // Domain match
      var domainMatch = (inputDomain.length >= 4 && rowWeb.length >= 4 && inputDomain === rowWeb);

      // Phone match
      var phoneMatch = (inputPhoneDigits.length >= 8 && rowPhoneDigits.length >= 8 &&
        (inputPhoneDigits === rowPhoneDigits || inputPhoneDigits.endsWith(rowPhoneDigits) || rowPhoneDigits.endsWith(inputPhoneDigits)));

      if (compMatch || emailMatch || domainMatch || phoneMatch) {
        rowIndex = j + 1;
        break;
      }
    }
  }

  // If updating an existing lead matched via duplicate detection, merge contact info so nothing is lost
  if (rowIndex > 0) {
    var existingRow = data[rowIndex - 1];
    var existingEmails = extractEmailsList(existingRow[3]);
    for (var k = 0; k < inputEmails.length; k++) {
      if (existingEmails.indexOf(inputEmails[k]) === -1) {
        existingEmails.push(inputEmails[k]);
      }
    }
    inputEmail = existingEmails.join(', ');

    var existingPhone = cleanPhoneForRead(existingRow[4]);
    if (inputPhone && existingPhone && cleanPhoneDigits(existingPhone) !== cleanPhoneDigits(inputPhone)) {
      inputPhone = existingPhone + ', ' + inputPhone;
    } else if (existingPhone) {
      inputPhone = existingPhone;
    }

    if (!inputWebsite && existingRow[2]) {
      inputWebsite = existingRow[2];
    }

    var existingNotes = String(existingRow[14] || '').trim();
    var newNotes = String(buyer["Notes"] || buyer.notes || '').trim();
    if (newNotes && existingNotes && existingNotes.indexOf(newNotes) === -1) {
      buyer["Notes"] = existingNotes + ' | ' + newNotes;
    } else if (existingNotes) {
      buyer["Notes"] = existingNotes;
    }
  }

  var finalSrNo = rowIndex > 0
    ? (data[rowIndex - 1][0] || targetSrNo)
    : (targetSrNo || (getTrueLastRow(sheet) + 1));

  var vals = [
    finalSrNo,
    buyer["Importer Company"] || buyer.company || "",
    buyer["Importer Website"] || buyer.website || "",
    buyer["Email"] || buyer.email || "",
    formatPhoneForWrite(buyer["Phone"] || buyer.phone),
    buyer["Connection Method"] || buyer.connectionMethod || "Email",
    buyer["Connection Date"] || buyer.connectionDate || "",
    buyer["First Email Date"] || buyer.firstEmailDate || "",
    buyer["Follow Up Date"] || buyer.nextDueDate || buyer.followUpDate || "",
    buyer["Client Reply"] || buyer.clientReply || "Pending",
    buyer["Last Email Date"] || buyer.lastEmailDate || "",
    String(buyer["Follow-Up Count"] || buyer.followupCount || "0"),
    buyer["Current Status"] || buyer.status || "New",
    buyer["Next Action"] || buyer.nextAction || "Follow-Up",
    buyer["Notes"] || buyer.notes || "",
    buyer["Market Type"] || buyer.marketType || "International"
  ];

  if (rowIndex > 0) {
    sheet.getRange(rowIndex, 1, 1, vals.length).setValues([vals]);
  } else {
    sheet.appendRow(vals);
  }
  return true;
}

function deleteBuyer(identifier) {
  var sheet = getBuyersSheet();
  if (!sheet) return false;
  var data = sheet.getDataRange().getValues();
  var target = String(identifier || '').replace('AF-', '').replace(/^0+/, '').trim().toLowerCase();
  if (!target) return false;

  for (var i = 1; i < data.length; i++) {
    var cellA = String(data[i][0] || '').replace('AF-', '').replace(/^0+/, '').trim().toLowerCase();
    var cellB = String(data[i][1] || '').trim().toLowerCase();
    if (cellA === target || cellB === target) {
      sheet.deleteRow(i + 1);
      renumberAllBuyersSequentially();
      return true;
    }
  }
  return false;
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. EXPOS (Expos Tab) - Multi-Day & Met Contacts Sync
// ═══════════════════════════════════════════════════════════════════════════

function getExposSheet() {
  var ss = getSpreadsheet();
  if (!ss) return null;

  var sheet = ss.getSheetByName("Expos");
  if (!sheet) {
    sheet = ss.insertSheet("Expos");
  }

  var headers = [
    "Expo ID", "Expo Name", "Expo Venue", "Expo Date", "City / Place", "Country",
    "Company Name", "Person Met", "Position / Designation",
    "Email(s)", "Phone Number(s)", "Company Website",
    "Address", "City", "Stall / Booth Location", "Discussion Notes"
  ];

  var firstCell = sheet.getRange(1, 1).getValue();
  if (String(firstCell).trim() !== "Expo ID") {
    sheet.clearContents();
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    sheet.getRange(1, 1, 1, headers.length)
      .setFontWeight("bold")
      .setBackground("#8B2C69")
      .setFontColor("#FFFFFF");
    sheet.setFrozenRows(1);
    for (var c = 1; c <= headers.length; c++) {
      sheet.setColumnWidth(c, 150);
    }
  }

  return sheet;
}

function getAllExpos() {
  var sheet = getExposSheet();
  if (!sheet) return [];

  var data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  var expoMap = {};
  var expoOrder = [];

  for (var i = 1; i < data.length; i++) {
    var row = data[i];
    var expoId = String(row[0] || '').trim();
    if (!expoId) continue;

    if (!expoMap[expoId]) {
      expoMap[expoId] = {
        id: expoId,
        name:     String(row[1] || ''),
        venue:    String(row[2] || ''),
        expoDate: String(row[3] || ''),
        place:    String(row[4] || ''),
        country:  String(row[5] || ''),
        contacts: []
      };
      expoOrder.push(expoId);
    }

    var companyName = String(row[6] || '').trim();
    if (companyName) {
      var emailsRaw = String(row[9] || '');
      var phonesRaw = String(row[10] || '');
      expoMap[expoId].contacts.push({
        id:              expoId + '_' + i,
        companyName:     companyName,
        personName:      String(row[7] || ''),
        personPosition:  String(row[8] || ''),
        emails:          emailsRaw ? emailsRaw.split(', ').filter(Boolean) : [],
        phoneNumbers:    phonesRaw ? phonesRaw.split(', ').filter(Boolean) : [],
        companyWebsite:  String(row[11] || ''),
        address:         String(row[12] || ''),
        city:            String(row[13] || ''),
        country:         String(row[5] || ''),
        venueAddress:    String(row[14] || ''),
        companyDetails:  String(row[15] || '')
      });
    }
  }

  return expoOrder.map(function(id) { return expoMap[id]; });
}

function upsertExpo(expo) {
  var sheet = getExposSheet();
  if (!sheet) return false;

  var expoId = String(expo.id || expo.expoId || '').trim();
  if (!expoId) return false;

  var data = sheet.getDataRange().getValues();
  var rowsForExpo = [];
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0] || '').trim() === expoId) {
      rowsForExpo.push(i + 1);
    }
  }
  if (rowsForExpo.length > 0) {
    for (var r = rowsForExpo.length - 1; r >= 0; r--) {
      sheet.deleteRow(rowsForExpo[r]);
    }
  }

  var contacts = expo.contacts || [];
  if (contacts.length === 0) {
    sheet.appendRow([expoId, expo.name || '', expo.venue || '', expo.expoDate || '', expo.place || '', expo.country || '']);
  } else {
    for (var c = 0; c < contacts.length; c++) {
      var contact = contacts[c];
      sheet.appendRow([
        expoId, expo.name || '', expo.venue || '', expo.expoDate || '', expo.place || '', expo.country || '',
        contact.companyName || '', contact.personName || '', contact.personPosition || '',
        (contact.emails || []).join(', '), (contact.phoneNumbers || []).join(', '),
        contact.companyWebsite || '', contact.address || '', contact.city || '',
        contact.venueAddress || '', contact.companyDetails || ''
      ]);
    }
  }
  return true;
}

function deleteExpo(identifier) {
  var sheet = getExposSheet();
  if (!sheet) return false;
  var data = sheet.getDataRange().getValues();
  var target = String(identifier || '').trim().toLowerCase();
  if (!target) return false;

  var deleted = false;
  for (var i = data.length - 1; i >= 1; i--) {
    if (String(data[i][0] || '').trim().toLowerCase() === target) {
      sheet.deleteRow(i + 1);
      deleted = true;
    }
  }
  return deleted;
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. PRODUCT PRICE LIST (PriceList Tab)
// ═══════════════════════════════════════════════════════════════════════════

function getPriceListSheet() {
  var ss = getSpreadsheet();
  if (!ss) return null;

  var sheet = ss.getSheetByName("PriceList");
  if (!sheet) {
    sheet = ss.insertSheet("PriceList");
  }

  var headers = [
    "Product ID", "Category", "Product Name", "Grade / Spec", "Packing",
    "Currency", "Current Ex-Factory Rate", "Prev Rate", "MOQ",
    "Validity", "Remarks", "Last Updated"
  ];

  var firstCell = sheet.getRange(1, 1).getValue();
  if (String(firstCell).trim() !== "Product ID") {
    var todayStr = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd");
    sheet.clearContents();
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    sheet.getRange(1, 1, 1, headers.length)
      .setFontWeight("bold")
      .setBackground("#0F766E")
      .setFontColor("#FFFFFF");
    sheet.setFrozenRows(1);
    for (var c = 1; c <= headers.length; c++) {
      sheet.setColumnWidth(c, 140);
    }
    // Pre-populate with official 24 baseline products
    var defaultProducts = getBaseline24Products(todayStr);
    sheet.getRange(2, 1, defaultProducts.length, headers.length).setValues(defaultProducts);
  }

  return sheet;
}

function getPriceHistorySheet() {
  var ss = getSpreadsheet();
  if (!ss) return null;

  var sheet = ss.getSheetByName("PriceHistory");
  if (!sheet) {
    sheet = ss.insertSheet("PriceHistory");
  }

  var headers = [
    "History ID", "Week / Validity", "Product ID", "Category", "Product Name",
    "Grade / Spec", "Packing", "Currency", "Price", "Change Amount",
    "Change %", "Recorded Date"
  ];

  var firstCell = sheet.getRange(1, 1).getValue();
  if (String(firstCell).trim() !== "History ID") {
    sheet.clearContents();
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    sheet.getRange(1, 1, 1, headers.length)
      .setFontWeight("bold")
      .setBackground("#1E3A8A")
      .setFontColor("#FFFFFF");
    sheet.setFrozenRows(1);
    for (var c = 1; c <= headers.length; c++) {
      sheet.setColumnWidth(c, 130);
    }
  }

  return sheet;
}

function getAllPrices() {
  var sheet = getPriceListSheet();
  if (!sheet) return [];
  var data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  var prices = [];
  for (var i = 1; i < data.length; i++) {
    var row = data[i];
    var id = String(row[0] || '').trim();
    var name = String(row[2] || '').trim();
    if (!id && !name) continue;

    var curPrice = parseFloat(row[6]) || 0;
    var prevPrice = parseFloat(row[7]) || 0;
    var diff = curPrice - prevPrice;
    var pct = prevPrice > 0 ? ((diff / prevPrice) * 100).toFixed(1) : "0.0";

    var curr = String(row[5] || '').trim();
    if (!curr || curr.indexOf('USD') >= 0) curr = "₹ / kg";

    prices.push({
      "id": id,
      "category": String(row[1] || 'General').trim(),
      "name": name,
      "grade": String(row[3] || '').trim(),
      "packing": String(row[4] || '20 kg Bag').trim(),
      "currency": curr,
      "currentPrice": curPrice,
      "prevPrice": prevPrice,
      "changeAmount": diff,
      "changePercent": pct,
      "trend": diff > 0 ? "up" : (diff < 0 ? "down" : "stable"),
      "moq": String(row[8] || '1000 kg').trim(),
      "validity": String(row[9] || 'Daily Spot Rate').trim(),
      "remarks": String(row[10] || '').trim(),
      "lastUpdated": formatDate(row[11])
    });
  }
  return prices;
}

function getAllPriceHistory() {
  var sheet = getPriceHistorySheet();
  if (!sheet) return [];
  var data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  var history = [];
  for (var i = 1; i < data.length; i++) {
    var row = data[i];
    var histId = String(row[0] || '').trim();
    if (!histId) continue;

    history.push({
      "historyId": histId,
      "weekLabel": String(row[1] || '').trim(),
      "productId": String(row[2] || '').trim(),
      "category": String(row[3] || '').trim(),
      "name": String(row[4] || '').trim(),
      "grade": String(row[5] || '').trim(),
      "packing": String(row[6] || '').trim(),
      "currency": String(row[7] || '₹ / kg').trim(),
      "price": parseFloat(row[8]) || 0,
      "changeAmount": parseFloat(row[9]) || 0,
      "changePercent": String(row[10] || '0.0%'),
      "recordedAt": formatDate(row[11])
    });
  }
  return history;
}

/**
 * Smart Date Upsert: If a history row exists for Product ID on today's date, update it.
 * Otherwise, append a new date entry. Only 1 final record per date!
 */
function upsertPriceHistory(histSheet, pId, weekStr, item, newPrice, diff, pct, todayStr) {
  var histData = histSheet.getDataRange().getValues();
  var histRowIndex = -1;

  for (var h = 1; h < histData.length; h++) {
    var rowHistId = String(histData[h][0] || '').trim();
    var rowDate = formatDate(histData[h][11]);
    var rowPId = String(histData[h][2] || '').trim();

    if (rowPId === pId && (rowDate === todayStr || rowHistId === ("HIST-" + pId + "-" + todayStr))) {
      histRowIndex = h + 1;
      break;
    }
  }

  var histId = "HIST-" + pId + "-" + todayStr;
  var histVals = [
    histId,
    weekStr,
    pId,
    String(item.category || 'General').trim(),
    String(item.name || '').trim(),
    String(item.grade || '').trim(),
    String(item.packing || '20 kg Bag').trim(),
    String(item.currency || '₹ / kg').trim(),
    newPrice,
    diff,
    pct,
    todayStr
  ];

  if (histRowIndex > 0) {
    histSheet.getRange(histRowIndex, 1, 1, histVals.length).setValues([histVals]);
  } else {
    histSheet.appendRow(histVals);
  }
}

/**
 * Save / Update a single product price directly in Google Sheets
 */
function upsertProductPrice(item, weekLabel) {
  var priceSheet = getPriceListSheet();
  var histSheet = getPriceHistorySheet();
  if (!priceSheet) return false;

  var pId = String(item.id || item.productId || '').trim();
  if (!pId) return false;

  var newPrice = parseFloat(item.currentPrice || item.price) || 0;
  var weekStr = String(weekLabel || item.validity || 'Daily Spot Rate').trim();
  var todayStr = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd");

  var existingData = priceSheet.getDataRange().getValues();
  var rowIndex = -1;
  var oldCurrentPrice = 0;

  for (var r = 1; r < existingData.length; r++) {
    var rowId = String(existingData[r][0] || '').trim();
    if (rowId === pId) {
      rowIndex = r + 1;
      oldCurrentPrice = parseFloat(existingData[r][6]) || 0;
      break;
    }
  }

  var prevPrice = (item.prevPrice !== undefined) ? (parseFloat(item.prevPrice) || 0) : oldCurrentPrice;
  if (prevPrice <= 0 && oldCurrentPrice > 0) prevPrice = oldCurrentPrice;
  var diff = newPrice - prevPrice;
  var pct = prevPrice > 0 ? ((diff / prevPrice) * 100).toFixed(1) + "%" : "0.0%";

  var rowVals = [
    pId,
    String(item.category || 'General').trim(),
    String(item.name || '').trim(),
    String(item.grade || '').trim(),
    String(item.packing || '20 kg Bag').trim(),
    String(item.currency || '₹ / kg').trim(),
    newPrice,
    prevPrice,
    String(item.moq || '1000 kg').trim(),
    weekStr,
    String(item.remarks || '').trim(),
    todayStr
  ];

  if (rowIndex > 0) {
    priceSheet.getRange(rowIndex, 1, 1, rowVals.length).setValues([rowVals]);
  } else {
    priceSheet.appendRow(rowVals);
  }

  if (histSheet && newPrice > 0) {
    upsertPriceHistory(histSheet, pId, weekStr, item, newPrice, diff, pct, todayStr);
  }

  return true;
}

/**
 * Delete a product from Google Sheet PriceList
 */
function deleteProductPrice(productId) {
  var sheet = getPriceListSheet();
  if (!sheet) return false;
  var target = String(productId || '').trim().toLowerCase();
  if (!target) return false;

  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    var rowId = String(data[i][0] || '').trim().toLowerCase();
    if (rowId === target) {
      sheet.deleteRow(i + 1);
      return true;
    }
  }
  return false;
}

/**
 * Batch update all prices (e.g. from Weekly Batch Editor or Sync 24 Items button)
 */
function saveWeeklyPrices(payload) {
  var priceSheet = getPriceListSheet();
  var histSheet = getPriceHistorySheet();
  if (!priceSheet || !histSheet) return false;

  var items = payload.prices || payload.items || (Array.isArray(payload) ? payload : []);
  var weekLabel = String(payload.weekLabel || payload.validity || "Daily Spot Rate").trim();
  var todayStr = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd");

  if (!items || items.length === 0) return false;

  var existingData = priceSheet.getDataRange().getValues();
  var rowMap = {};
  for (var r = 1; r < existingData.length; r++) {
    var pId = String(existingData[r][0] || '').trim();
    if (pId) rowMap[pId] = r + 1;
  }

  for (var i = 0; i < items.length; i++) {
    var item = items[i];
    var pid = String(item.id || item.productId || ('PROD-' + (i + 1))).trim();
    var newPrice = parseFloat(item.currentPrice || item.price) || 0;
    var targetRow = rowMap[pid];

    var oldCurrentPrice = 0;
    if (targetRow) {
      oldCurrentPrice = parseFloat(existingData[targetRow - 1][6]) || 0;
    }
    var prevPrice = (item.prevPrice !== undefined) ? (parseFloat(item.prevPrice) || 0) : oldCurrentPrice;
    if (prevPrice <= 0 && oldCurrentPrice > 0) prevPrice = oldCurrentPrice;

    var diff = newPrice - prevPrice;
    var pct = prevPrice > 0 ? ((diff / prevPrice) * 100).toFixed(1) + "%" : "0.0%";

    var rowVals = [
      pid,
      String(item.category || 'General').trim(),
      String(item.name || '').trim(),
      String(item.grade || '').trim(),
      String(item.packing || '20 kg Bag').trim(),
      String(item.currency || '₹ / kg').trim(),
      newPrice,
      prevPrice,
      String(item.moq || '1000 kg').trim(),
      weekLabel,
      String(item.remarks || '').trim(),
      todayStr
    ];

    if (targetRow) {
      priceSheet.getRange(targetRow, 1, 1, rowVals.length).setValues([rowVals]);
    } else {
      priceSheet.appendRow(rowVals);
      rowMap[pid] = priceSheet.getLastRow();
    }

    if (newPrice > 0) {
      upsertPriceHistory(histSheet, pid, weekLabel, item, newPrice, diff, pct, todayStr);
    }
  }

  return true;
}

/**
 * ============================================================================
 * 🔢 RENUMBER ALL BUYERS SEQUENTIALLY (Sheet1 Column A)
 * Eliminates all gaps and duplicate numbers. Ensures Sr. No. is strictly 1 to N!
 * ============================================================================
 */
function renumberAllBuyersSequentially() {
  var sheet = getBuyersSheet();
  if (!sheet) return 0;
  var lastRow = sheet.getLastRow();
  if (lastRow <= 1) return 0;

  var count = lastRow - 1;
  var newValues = [];
  for (var i = 1; i <= count; i++) {
    newValues.push([i]);
  }

  sheet.getRange(2, 1, count, 1).setValues(newValues);
  Logger.log("✅ Successfully renumbered " + count + " buyers from 1 to " + count + "!");
  return count;
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// 🛡️ ADVANCED DUPLICATE DETECTION & DEDUPLICATION TOOLS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

function normalizeCompanyName(name) {
  var s = String(name || '').trim().toLowerCase();
  if (!s || s === 'n/a' || s === '-' || s.indexOf('importer #') === 0) return '';
  s = s.replace(/[^a-z0-9\s]/g, ' ');
  s = s.replace(/\b(sole member co ltd|company limited|company ltd|pvt ltd|private limited|corp|corporation|inc|incorporated|ltd|limited|llc|pvt|co)\b/g, ' ');
  s = s.replace(/\s+/g, ' ').trim();
  return s;
}

function extractDomain(url) {
  var s = String(url || '').trim().toLowerCase();
  if (!s || s === 'n/a' || s === '-' || s.indexOf('@') !== -1) return '';
  s = s.replace('https://', '').replace('http://', '').replace('www.', '');
  s = s.split('/')[0].split('?')[0].split('#')[0].trim();
  if (s.length < 4 || s.indexOf('.') === -1) return '';
  return s;
}

function extractEmailsList(emailField) {
  var s = String(emailField || '').trim();
  if (!s) return [];
  var split = s.split(/[,;\/\s]+/);
  var list = [];
  for (var i = 0; i < split.length; i++) {
    var clean = split[i].replace(/["']/g, '').trim().toLowerCase();
    if (clean.indexOf('@') !== -1 && clean.indexOf('n/a') !== 0 && clean.indexOf('-') !== 0 && list.indexOf(clean) === -1) {
      list.push(clean);
    }
  }
  return list;
}

function cleanPhoneDigits(phone) {
  return String(phone || '').replace(/\D/g, '').replace(/^0+/, '');
}

/**
 * â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
 * 🧹 ONE-CLICK TOOL: MERGE ALL DUPLICATE BUYERS & RENUMBER 1..N
 * Run this ONCE from Apps Script editor > Run > cleanExistingDuplicatesAndRenumber
 * â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
 */
function cleanExistingDuplicatesAndRenumber() {
  var sheet = getBuyersSheet();
  if (!sheet) return { status: "error", message: "Sheet1 not found" };
  var lastRow = sheet.getLastRow();
  if (lastRow <= 1) return { status: "success", mergedCount: 0, remainingBuyers: 0 };

  var data = sheet.getRange(1, 1, lastRow, 16).getValues();
  var rowsToDelete = [];
  var clusters = [];

  for (var i = 1; i < data.length; i++) {
    var row = data[i];
    var comp = normalizeCompanyName(row[1]);
    var web = extractDomain(row[2]);
    var emails = extractEmailsList(row[3]);
    var phone = cleanPhoneDigits(row[4]);

    if (!comp && !web && emails.length === 0) continue;

    var matchIdx = -1;
    for (var c = 0; c < clusters.length; c++) {
      var cl = clusters[c];
      var compMatch = (comp && cl.comp && comp.length >= 3 && cl.comp.length >= 3 && comp === cl.comp);
      var domainMatch = (web && cl.web && web.length >= 4 && cl.web.length >= 4 && web === cl.web);
      var emailMatch = false;
      for (var e = 0; e < emails.length; e++) {
        if (cl.emails.indexOf(emails[e]) !== -1) {
          emailMatch = true;
          break;
        }
      }
      var phoneMatch = (phone && cl.phone && phone.length >= 8 && cl.phone.length >= 8 &&
        (phone === cl.phone || phone.endsWith(cl.phone) || cl.phone.endsWith(phone)));

      if (compMatch || domainMatch || emailMatch || phoneMatch) {
        matchIdx = c;
        break;
      }
    }

    if (matchIdx !== -1) {
      var targetCl = clusters[matchIdx];
      var primaryDataIdx = targetCl.dataIdx;

      // Merge email
      var primaryEmailStr = String(data[primaryDataIdx][3] || '');
      var primaryEmails = extractEmailsList(primaryEmailStr);
      for (var em = 0; em < emails.length; em++) {
        if (primaryEmails.indexOf(emails[em]) === -1) {
          primaryEmails.push(emails[em]);
          if (targetCl.emails.indexOf(emails[em]) === -1) targetCl.emails.push(emails[em]);
        }
      }
      data[primaryDataIdx][3] = primaryEmails.join(', ');

      // Merge phone
      var primaryPhone = cleanPhoneForRead(data[primaryDataIdx][4]);
      var rowPhone = cleanPhoneForRead(row[4]);
      if (rowPhone && !primaryPhone.includes(cleanPhoneDigits(rowPhone))) {
        data[primaryDataIdx][4] = primaryPhone ? (primaryPhone + ', ' + rowPhone) : rowPhone;
      }

      // Merge website
      if (!String(data[primaryDataIdx][2] || '').trim() && row[2]) {
        data[primaryDataIdx][2] = row[2];
        targetCl.web = extractDomain(row[2]);
      }

      // Merge notes
      var primaryNotes = String(data[primaryDataIdx][14] || '').trim();
      var rowNotes = String(row[14] || '').trim();
      if (rowNotes && primaryNotes.indexOf(rowNotes) === -1) {
        data[primaryDataIdx][14] = primaryNotes ? (primaryNotes + ' | ' + rowNotes) : rowNotes;
      }

      rowsToDelete.push(i + 1);
    } else {
      clusters.push({
        dataIdx: i,
        sheetRow: i + 1,
        comp: comp,
        web: web,
        emails: emails,
        phone: phone
      });
    }
  }

  // Update merged primary rows in sheet
  for (var c2 = 0; c2 < clusters.length; c2++) {
    var pIdx = clusters[c2].dataIdx;
    var rowVals = data[pIdx];
    sheet.getRange(clusters[c2].sheetRow, 1, 1, 16).setValues([rowVals]);
  }

  // Delete duplicate rows from bottom to top
  rowsToDelete.sort(function(a, b) { return b - a; });
  for (var d = 0; d < rowsToDelete.length; d++) {
    sheet.deleteRow(rowsToDelete[d]);
  }

  // Renumber remaining buyers 1..N
  var remaining = renumberAllBuyersSequentially();
  Logger.log("✅ Duplicates cleaned: " + rowsToDelete.length + " duplicate rows merged and deleted.");
  Logger.log("✅ Remaining unique buyers: " + remaining + " sequentially renumbered 1 to " + remaining + "!");
  return {
    status: "success",
    mergedCount: rowsToDelete.length,
    remainingBuyers: remaining
  };
}