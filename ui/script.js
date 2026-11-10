// Glitch Studios - glitch-securityCameras (NUI)
// One message listener. The page has no NUI focus, so it never posts back to the game.

(() => {
    const el = (id) => document.getElementById(id);
    const root = el('cameraSystem');
    let clockTimer = null;
    let noticeTimer = null;
    let hideTimer = null;

    const ui = { camPrefix: 'CAM_', mode: 'MODE:', targetIdentified: 'TARGET IDENTIFIED' };

    function camLabel(id) {
        return ui.camPrefix + String(id).padStart(2, '0');
    }

    function updateClock() {
        const now = new Date();
        el('timestamp').textContent = now.toLocaleTimeString();
        el('date').textContent = now.toLocaleDateString();
    }

    function setMode(mode) {
        el('camera-mode').textContent = ui.mode + ' ' + String(mode || 'normal').toUpperCase();
    }

    function setInfo(data) {
        if (data.cameraId !== undefined && data.cameraId !== null) {
            el('cameraId').textContent = camLabel(data.cameraId);
        }
        if (data.cameraName) el('camera-name').textContent = String(data.cameraName).toUpperCase();
        if (data.location) el('camera-location').textContent = String(data.location).toUpperCase();
    }

    function setTarget(text) {
        const prompt = el('interactionPrompt');
        const reticle = document.querySelector('.camera-reticle');
        const existing = el('targeting-indicator');

        if (text) {
            el('interactionText').textContent = text;
            prompt.classList.add('active');
            if (reticle && !existing) reticle.appendChild(buildTargetIndicator());
        } else {
            prompt.classList.remove('active');
            if (existing) existing.remove();
        }
    }

    function buildTargetIndicator() {
        const box = document.createElement('div');
        box.id = 'targeting-indicator';
        ['scan-ring', 'targeting-corner corner-top-left', 'targeting-corner corner-top-right',
            'targeting-corner corner-bottom-left', 'targeting-corner corner-bottom-right'].forEach((cls) => {
            const part = document.createElement('div');
            part.className = cls;
            box.appendChild(part);
        });
        const label = document.createElement('div');
        label.className = 'target-text';
        label.textContent = ui.targetIdentified;
        box.appendChild(label);
        requestAnimationFrame(() => box.classList.add('active'));
        return box;
    }

    function notify(message, style) {
        const box = el('notification');
        el('notificationText').textContent = String(message);
        box.className = 'notification active ' + (style || 'info');
        clearTimeout(noticeTimer);
        noticeTimer = setTimeout(() => box.classList.remove('active'), 3000);
    }

    function applyLabels(labels) {
        if (!labels || typeof labels !== 'object') return;
        document.querySelectorAll('[data-label]').forEach((node) => {
            const value = labels[node.dataset.label];
            if (typeof value === 'string') node.textContent = value;
        });
    }

    function show(data) {
        clearTimeout(hideTimer);
        if (data.ui && typeof data.ui === 'object') Object.assign(ui, data.ui);
        applyLabels(data.labels);
        setInfo(data);
        setMode('normal');
        setTarget(null);
        updateClock();
        clearInterval(clockTimer);
        clockTimer = setInterval(updateClock, 1000);
        root.style.display = 'block';
        setTimeout(() => root.classList.add('visible'), 10);
    }

    function hide() {
        clearInterval(clockTimer);
        clockTimer = null;
        root.classList.remove('visible');
        setTarget(null);
        hideTimer = setTimeout(() => { root.style.display = 'none'; }, 500);
    }

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || typeof data.type !== 'string') return;

        switch (data.type) {
            case 'showCameraUI': show(data); break;
            case 'hideCameraUI': hide(); break;
            case 'updateCameraInfo': setInfo(data); break;
            case 'setViewMode': setMode(data.mode); break;
            case 'setTarget': setTarget(data.text); break;
            case 'showNotification': notify(data.message, data.style); break;
        }
    });
})();
