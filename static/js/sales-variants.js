// Enhanced Product Variant Management for Sales
let variantCounter = 0;
let isClassicView = window.isClassicView || false; // Default to Enhanced view for multiple items

function addProductVariant() {
    variantCounter++;
    const container = document.getElementById('productVariantsContainer');
    
    // Remove info alert if it exists
    const infoAlert = container.querySelector('.alert-info');
    if (infoAlert) {
        infoAlert.remove();
    }
    
    const variantDiv = document.createElement('div');
    variantDiv.className = 'card mb-3 product-variant';
    variantDiv.id = `variant_${variantCounter}`;
    
    // Get products, sizes, and colors data from global variables
    const productsOptions = window.productsData ? window.productsData.map(product => `
        <option value="${product.id}" data-price="${product.price}" data-size="${product.size}" data-color="${product.color}">
            ${product.name} - ${product.category} (${product.size}, ${product.color}) - ৳${parseFloat(product.price).toFixed(2)}
        </option>
    `).join('') : '';
    
    const sizesOptions = window.sizesData ? window.sizesData.map(size => `
        <option value="${size.name}">${size.name}</option>
    `).join('') : '';
    
    const colorsOptions = window.colorsData ? window.colorsData.map(color => `
        <option value="${color.name}">${color.name}</option>
    `).join('') : '';
    
    variantDiv.innerHTML = `
        <div class="card-header d-flex justify-content-between align-items-center">
            <h6 class="mb-0">Product Variant #${variantCounter}</h6>
            <button type="button" class="btn btn-outline-danger btn-sm" onclick="removeProductVariant(${variantCounter})">
                <i class="fas fa-trash"></i>
            </button>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-4">
                    <label class="form-label">Select Product *</label>
                    <select class="form-select" name="variant_${variantCounter}_product" onchange="updateVariantPrice(${variantCounter})" required>
                        <option value="">Choose a product...</option>
                        ${productsOptions}
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label">Size Override</label>
                    <select class="form-select" name="variant_${variantCounter}_size">
                        <option value="">Use product size</option>
                        ${sizesOptions}
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label">Color Override</label>
                    <select class="form-select" name="variant_${variantCounter}_color">
                        <option value="">Use product color</option>
                        ${colorsOptions}
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label">Item Numbers *</label>
                    <input type="text" class="form-control" name="variant_${variantCounter}_items" 
                           placeholder="e.g., 40 or 1,2,3" 
                           onchange="updateVariantTotal(${variantCounter})" required>
                </div>
                <div class="col-md-2">
                    <label class="form-label">Total</label>
                    <div class="form-control-plaintext fw-bold text-success" id="variant_${variantCounter}_total">৳0.00</div>
                </div>
            </div>
        </div>
    `;
    
    container.appendChild(variantDiv);
    
    // Apply current enhanced search filter to the new variant if there's a search term
    const enhancedSearchInput = document.getElementById('enhancedProductSearch');
    if (enhancedSearchInput && enhancedSearchInput.value.trim()) {
        // Use a small delay to ensure the DOM is updated
        setTimeout(() => {
            if (typeof filterEnhancedProducts === 'function') {
                filterEnhancedProducts();
            }
        }, 50);
    }
    
    updateGrandTotal();
}

function removeProductVariant(variantId) {
    const variantDiv = document.getElementById(`variant_${variantId}`);
    if (variantDiv) {
        variantDiv.remove();
        updateGrandTotal();
        
        // Show info alert if no variants remain
        const container = document.getElementById('productVariantsContainer');
        const variants = container.querySelectorAll('.product-variant');
        if (variants.length === 0) {
            container.innerHTML = `
                <div class="alert alert-info">
                    <i class="fas fa-info-circle me-2"></i>
                    <strong>New Feature:</strong> You can now add the same product multiple times with different colors and sizes! 
                    Click "Add Product Variant" to add more entries for the same or different products.
                </div>
            `;
        }
    }
}

function updateVariantPrice(variantId) {
    const productSelect = document.querySelector(`select[name="variant_${variantId}_product"]`);
    const selectedOption = productSelect.selectedOptions[0];
    
    if (selectedOption && selectedOption.value) {
        const price = selectedOption.getAttribute('data-price');
        const size = selectedOption.getAttribute('data-size');
        const color = selectedOption.getAttribute('data-color');
        
        // Update size and color defaults
        const sizeSelect = document.querySelector(`select[name="variant_${variantId}_size"]`);
        const colorSelect = document.querySelector(`select[name="variant_${variantId}_color"]`);
        
        // Set placeholders to show product defaults
        if (sizeSelect && sizeSelect.options[0]) {
            sizeSelect.options[0].text = `Use product size (${size})`;
        }
        if (colorSelect && colorSelect.options[0]) {
            colorSelect.options[0].text = `Use product color (${color})`;
        }
        
        updateVariantTotal(variantId);
    }
}

function updateVariantTotal(variantId) {
    const productSelect = document.querySelector(`select[name="variant_${variantId}_product"]`);
    const itemsInput = document.querySelector(`input[name="variant_${variantId}_items"]`);
    const totalDiv = document.getElementById(`variant_${variantId}_total`);
    
    if (productSelect && productSelect.value && itemsInput && itemsInput.value && totalDiv) {
        const selectedOption = productSelect.selectedOptions[0];
        const price = parseFloat(selectedOption.getAttribute('data-price'));
        const itemCount = parseItemNumbers(itemsInput.value);
        const total = price * itemCount;
        
        totalDiv.textContent = `৳${total.toFixed(2)}`;
        updateGrandTotal();
    } else if (totalDiv) {
        totalDiv.textContent = '৳0.00';
        updateGrandTotal();
    }
}

function updateGrandTotal() {
    let totalItems = 0;
    let productTotal = 0;
    
    // Calculate totals from variants
    const variants = document.querySelectorAll('.product-variant');
    variants.forEach(variant => {
        const itemsInput = variant.querySelector('input[name*="_items"]');
        const totalDiv = variant.querySelector('[id*="_total"]');
        
        if (itemsInput && itemsInput.value && totalDiv) {
            const itemCount = parseItemNumbers(itemsInput.value);
            const variantTotal = parseFloat(totalDiv.textContent.replace('৳', ''));
            
            totalItems += itemCount;
            productTotal += variantTotal;
        }
    });
    
    // Update display
    const totalItemsDiv = document.getElementById('total_items');
    const productGrandTotalDiv = document.getElementById('product_grand_total');
    const grandTotalDiv = document.getElementById('grand_total');
    const deliveryChargeSelect = document.getElementById('multi_delivery_charge');
    
    if (totalItemsDiv) totalItemsDiv.textContent = totalItems;
    if (productGrandTotalDiv) productGrandTotalDiv.textContent = `৳${productTotal.toFixed(2)}`;
    
    // Calculate grand total with delivery
    const deliveryCharge = deliveryChargeSelect ? parseFloat(deliveryChargeSelect.value || 0) : 0;
    const grandTotal = productTotal + deliveryCharge;
    if (grandTotalDiv) grandTotalDiv.textContent = `৳${grandTotal.toFixed(2)}`;
}

function toggleProductInterface() {
    const variantsContainer = document.getElementById('productVariantsContainer');
    const originalTable = document.getElementById('originalProductsTable');
    const toggleBtn = document.querySelector('button[onclick="toggleProductInterface()"]');
    
    // Update both local and global variables
    isClassicView = !isClassicView;
    window.isClassicView = isClassicView;
    
    console.log('Toggled to classic view:', isClassicView);
    
    if (isClassicView) {
        if (variantsContainer) variantsContainer.style.display = 'none';
        if (originalTable) originalTable.style.display = 'block';
        if (toggleBtn) toggleBtn.innerHTML = '<i class="fas fa-exchange-alt me-1"></i>Switch to Enhanced View';
        
        // Clear enhanced search when switching to classic view
        if (typeof clearEnhancedSearch === 'function') {
            clearEnhancedSearch();
        }
    } else {
        if (variantsContainer) variantsContainer.style.display = 'block';
        if (originalTable) originalTable.style.display = 'none';
        if (toggleBtn) toggleBtn.innerHTML = '<i class="fas fa-exchange-alt me-1"></i>Switch to Classic View';
        
        // Add initial variant if switching to enhanced view and no variants exist
        const variants = variantsContainer.querySelectorAll('.product-variant');
        if (variants.length === 0) {
            addProductVariant();
        }
        
        // Clear table search when switching to enhanced view
        const tableSearchInput = document.getElementById('productSearch');
        if (tableSearchInput) {
            tableSearchInput.value = '';
            if (typeof filterProducts === 'function') {
                filterProducts();
            }
        }
    }
}

function parseItemNumbers(itemNumbers) {
    if (!itemNumbers) return 0;
    
    let total = 0;
    const parts = itemNumbers.split(',');
    
    for (let part of parts) {
        part = part.trim();
        if (part.includes('-')) {
            const [start, end] = part.split('-').map(n => parseInt(n.trim()));
            if (!isNaN(start) && !isNaN(end) && start <= end) {
                total += (end - start + 1);
            }
        } else {
            const num = parseInt(part);
            if (!isNaN(num)) {
                total += num;
            }
        }
    }
    
    return total;
}


// Validation function is now in the main HTML file to avoid conflicts

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    // Only add initial variant if we're in enhanced view (not classic view)
    setTimeout(() => {
        if (document.getElementById('productVariantsContainer') && !isClassicView) {
            addProductVariant();
        }
    }, 100);
    
    // Listen for delivery charge changes
    const deliveryChargeSelect = document.getElementById('multi_delivery_charge');
    if (deliveryChargeSelect) {
        deliveryChargeSelect.addEventListener('change', updateGrandTotal);
    }
});
