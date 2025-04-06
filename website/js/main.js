/**
 * MacMonitor Website - Main JavaScript File
 * Handles interactive features for the MacMonitor website
 */

document.addEventListener('DOMContentLoaded', function() {
    // Mobile navigation toggle
    const mobileMenuButton = document.querySelector('nav button');
    if (mobileMenuButton) {
        const mobileMenu = document.createElement('div');
        mobileMenu.className = 'mobile-menu hidden fixed inset-0 bg-gray-900 bg-opacity-75 z-50';
        mobileMenu.innerHTML = `
            <div class="bg-white h-auto w-full max-w-xs p-6 overflow-y-auto">
                <div class="flex justify-between items-center mb-6">
                    <a href="index.html" class="flex items-center space-x-2">
                        <img src="img/logo.svg" alt="MacMonitor Logo" class="h-8 w-auto">
                        <span class="font-semibold text-xl text-gray-900">MacMonitor</span>
                    </a>
                    <button class="close-menu text-gray-500 hover:text-gray-900">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                <nav class="flex flex-col space-y-4">
                    <a href="index.html" class="py-2 px-3 rounded hover:bg-gray-100">Home</a>
                    <a href="guide.html" class="py-2 px-3 rounded hover:bg-gray-100">Guide</a>
                    <a href="download.html" class="py-2 px-3 rounded hover:bg-gray-100">Download</a>
                    <a href="https://github.com/user/mac-system-monitor" class="py-2 px-3 rounded hover:bg-gray-100">GitHub</a>
                </nav>
            </div>
        `;
        document.body.appendChild(mobileMenu);

        // Set active link in mobile menu based on current page
        const currentPage = window.location.pathname.split('/').pop() || 'index.html';
        document.querySelectorAll('.mobile-menu a').forEach(link => {
            const linkPage = link.getAttribute('href');
            if (linkPage === currentPage) {
                link.classList.add('bg-gray-100', 'text-indigo-600', 'font-medium');
            }
        });

        // Toggle mobile menu
        mobileMenuButton.addEventListener('click', () => {
            mobileMenu.classList.remove('hidden');
            document.body.classList.add('overflow-hidden');
        });

        // Close mobile menu
        const closeButton = mobileMenu.querySelector('.close-menu');
        if (closeButton) {
            closeButton.addEventListener('click', () => {
                mobileMenu.classList.add('hidden');
                document.body.classList.remove('overflow-hidden');
            });
        }

        // Close when clicking outside menu
        mobileMenu.addEventListener('click', (e) => {
            if (!e.target.closest('.bg-white')) {
                mobileMenu.classList.add('hidden');
                document.body.classList.remove('overflow-hidden');
            }
        });
    }

    // Add copy functionality to code blocks
    document.querySelectorAll('pre').forEach(codeBlock => {
        // Only add button if not already present
        if (!codeBlock.querySelector('.copy-btn')) {
            const copyButton = document.createElement('button');
            copyButton.className = 'copy-btn';
            copyButton.textContent = 'Copy';
            
            copyButton.addEventListener('click', () => {
                const code = codeBlock.querySelector('code') ? 
                    codeBlock.querySelector('code').innerText : 
                    codeBlock.innerText;
                
                navigator.clipboard.writeText(code).then(() => {
                    copyButton.textContent = 'Copied!';
                    setTimeout(() => {
                        copyButton.textContent = 'Copy';
                    }, 2000);
                }).catch(err => {
                    console.error('Failed to copy: ', err);
                    copyButton.textContent = 'Failed';
                    setTimeout(() => {
                        copyButton.textContent = 'Copy';
                    }, 2000);
                });
            });
            
            codeBlock.style.position = 'relative';
            codeBlock.appendChild(copyButton);
        }
    });

    // Feature card animations
    const featureCards = document.querySelectorAll('.bg-gray-50.p-6.rounded-lg');
    featureCards.forEach(card => {
        card.classList.add('feature-card');
    });

    // Set current year in footer copyright
    const currentYear = new Date().getFullYear();
    const copyrightYear = document.querySelector('footer .text-gray-500');
    if (copyrightYear) {
        copyrightYear.innerHTML = copyrightYear.innerHTML.replace('2025', currentYear);
    }

    // Add smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                targetElement.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
                
                // Update URL but without scrolling
                history.pushState(null, null, targetId);
            }
        });
    });

    // Initialize any carousels or sliders if present
    const testimonialContainer = document.querySelector('.testimonial-container');
    if (testimonialContainer && typeof Splide !== 'undefined') {
        new Splide('.testimonial-container', {
            type: 'loop',
            perPage: 1,
            autoplay: true,
            interval: 5000,
            pauseOnHover: true,
            arrows: true,
            pagination: true,
        }).mount();
    }
});
