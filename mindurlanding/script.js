document.addEventListener('DOMContentLoaded', () => {

    // ---------------------------------------------------------
    // SCROLL ANIMATIONS (Intersection Observer)
    // ---------------------------------------------------------
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                // Optional: Stop observing once visible to save performance
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    const fadeElements = document.querySelectorAll('.fade-on-scroll');
    fadeElements.forEach(el => observer.observe(el));


    // ---------------------------------------------------------
    // PARALLAX EFFECT ON HERO IMAGE
    // ---------------------------------------------------------
    const heroImage = document.querySelector('.phone-mockup');
    const heroSection = document.querySelector('.hero');

    if (heroImage && heroSection) {
        heroSection.addEventListener('mousemove', (e) => {
            // Calculate mouse position relative to center
            const x = (window.innerWidth / 2 - e.clientX) / 40;
            const y = (window.innerHeight / 2 - e.clientY) / 40;

            // Apply varying levels of movement
            heroImage.style.transform = `translate(${x}px, ${y}px) rotateY(${x * 0.5}deg) rotateX(${-y * 0.5}deg)`;
        });

        // Reset on mouse leave
        heroSection.addEventListener('mouseleave', () => {
            heroImage.style.transform = `translate(0, 0) rotateY(0) rotateX(0)`;
        });
    }


    // ---------------------------------------------------------
    // AURORA CHAT DEMO ANIMATION
    // ---------------------------------------------------------
    // Simulating the typing indicator turning into a message
    const auroraMsg = document.querySelector('.msg.aurora');
    const typingIndicator = document.querySelector('.typing');

    // Only run this animation once when the section is viewed
    const auroraSection = document.querySelector('#aurora');
    let messageShown = false;

    const chatObserver = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && !messageShown) {
            messageShown = true;

            // Wait 2 seconds, then remove typing and show text fully?
            // Actually, for this demo we just keep it simple or expand it.
            // Let's just pulsate the glow more when visible.
            const glow = document.querySelector('.aurora-glow');
            if (glow) glow.style.animationDuration = '2s';
        }
    }, { threshold: 0.5 });

    if (auroraSection) chatObserver.observe(auroraSection);


    // ---------------------------------------------------------
    // FAQ ACCORDION
    // ---------------------------------------------------------
    const accordionItems = document.querySelectorAll('.accordion-item');

    accordionItems.forEach(item => {
        const header = item.querySelector('.accordion-header');

        header.addEventListener('click', () => {
            const isActive = item.classList.contains('active');

            // Close all other items
            accordionItems.forEach(otherItem => {
                otherItem.classList.remove('active');
            });

            // Toggle current item
            if (!isActive) {
                item.classList.add('active');
            }
        });
    });
});
