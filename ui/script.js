// -- Glitch Security Camera System
// -- Copyright (C) 2024 Glitch
// -- 
// -- This program is free software: you can redistribute it and/or modify
// -- it under the terms of the GNU General Public License as published by
// -- the Free Software Foundation, either version 3 of the License, or
// -- (at your option) any later version.
// -- 
// -- This program is distributed in the hope that it will be useful,
// -- but WITHOUT ANY WARRANTY; without even the implied warranty of
// -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// -- GNU General Public License for more details.
// -- 
// -- You should have received a copy of the GNU General Public License
// -- along with this program. If not, see <https://www.gnu.org/licenses/>.

let currentCamera = 1;
let notificationTimeout = null;

let currentReticleState = 'default';
let reticleAnimationRunning = false;

let hackingActive = false;
let currentStage = 0;
let progressValue = 0;
let holdInterval = null;
let animationFrame = null;
let targetSegments = [];
let currentProgress = null;

let interactablePropInView = null;

let currentViewMode = 'normal'; // 'normal', 'thermal' and 'nightvision'

document.addEventListener('DOMContentLoaded', function() {
    const cameraSystem = document.getElementById('cameraSystem');
    if (cameraSystem) {
        cameraSystem.style.display = 'none';
    }
});


window.addEventListener('mousedown', (e) => {
    if (e.button === 0 && interactablePropInView && !hackingActive) {
        console.log("Starting hack for prop:", interactablePropInView);
        
        post({
            type: 'startHack',
            propId: interactablePropInView.id
        });
        
        startHoldPhase();
    }
});

window.addEventListener('mouseup', (e) => {
    if (e.button === 0 && hackingActive) {
        if (currentStage === 0) {
            clearInterval(holdInterval);
            holdInterval = setInterval(decreaseProgress, 50);
        } else {
            checkTimingClick();
        }
    }
});

// unused now used to be used to built in hack minigame but I never completed it.
function startHoldPhase() {
    console.log("Starting hold phase");
    hackingActive = true;
    currentStage = 0;
    progressValue = 0;
    
    const hackInterface = document.getElementById('hacking-interface');
    hackInterface.style.display = 'block';
    
    const circle1 = document.querySelector('.hack-circle-1');
    const progressBar = document.createElement('div');
    progressBar.className = 'progress-fill';
    progressBar.style.width = '0%';
    progressBar.style.height = '8px';
    progressBar.style.top = 'calc(50% - 4px)';
    progressBar.style.left = '50%';
    progressBar.style.backgroundColor = 'rgba(255, 255, 255, 0.9)';
    circle1.appendChild(progressBar);
    
    currentProgress = progressBar;
    
    holdInterval = setInterval(increaseProgress, 50);
}

function increaseProgress() {
    progressValue += 1;
    
    if (currentProgress) {
        currentProgress.style.width = `${progressValue}%`;
        currentProgress.style.transform = `rotate(${progressValue * 3.6}deg)`;
    }
    
    if (progressValue >= 100) {
        clearInterval(holdInterval);
        startTimingPhase();
    }
}

function decreaseProgress() {
    progressValue -= 1;
    
    if (currentProgress) {
        currentProgress.style.width = `${progressValue}%`;
        currentProgress.style.transform = `rotate(${progressValue * 3.6}deg)`;
    }
    
    if (progressValue <= 0) {
        clearInterval(holdInterval);
        endHacking(false);
    }
}

// same as before also from the old minigame
function startTimingPhase() {
    currentStage++;
    
    if (holdInterval) {
        clearInterval(holdInterval);
        holdInterval = null;
    }
    
    const nextCircle = document.querySelector(`.hack-circle-${currentStage + 1}`);
    if (nextCircle) {
        nextCircle.style.display = 'block';
        
        const targetAngle = Math.random() * 360;
        const targetWidth = 45 - (currentStage * 10);
        
        const targetSegment = document.createElement('div');
        targetSegment.className = 'target-segment';
        targetSegment.style.width = `${targetWidth}px`;
        targetSegment.style.top = 'calc(50% - 6px)';
        targetSegment.style.left = '50%';
        targetSegment.style.transform = `rotate(${targetAngle}deg)`;
        nextCircle.appendChild(targetSegment);
        
        targetSegments[currentStage] = {
            element: targetSegment,
            startAngle: targetAngle,
            endAngle: (targetAngle + targetWidth / 2) % 360
        };
        
        const progressBar = document.createElement('div');
        progressBar.className = 'progress-fill';
        progressBar.style.width = '0%';
        progressBar.style.height = '8px';
        progressBar.style.top = 'calc(50% - 4px)';
        progressBar.style.left = '50%';
        nextCircle.appendChild(progressBar);
        
        currentProgress = progressBar;
        
        progressValue = 0;
        animateProgress();
    } else {
        endHacking(true);
    }
}

function animateProgress() {
    progressValue += 0.8;
    
    if (currentProgress) {
        const rotation = progressValue * 3.6;
        currentProgress.style.width = `${progressValue}%`;
        currentProgress.style.transform = `rotate(${rotation}deg)`;
    }
    
    if (progressValue >= 100) {
        endHacking(false);
        return;
    }
    
    animationFrame = requestAnimationFrame(animateProgress);
}

function checkTimingClick() {
    const currentAngle = progressValue * 3.6;
    const target = targetSegments[currentStage];
    
    if (isAngleInRange(currentAngle, target.startAngle, target.endAngle)) {
        cancelAnimationFrame(animationFrame);
        
        if (currentStage < 3) {
            startTimingPhase();
        } else {
            endHacking(true);
        }
    } else {
        endHacking(false);
    }
}

function isAngleInRange(angle, start, end) {
    if (start > end) {
        return angle >= start || angle <= end;
    }
    return angle >= start && angle <= end;
}

function endHacking(success) {
    if (holdInterval) {
        clearInterval(holdInterval);
        holdInterval = null;
    }
    
    if (animationFrame) {
        cancelAnimationFrame(animationFrame);
        animationFrame = null;
    }
    
    const resultElement = document.querySelector('.hack-result');
    resultElement.textContent = success ? 'ACCESS GRANTED' : 'ACCESS DENIED';
    resultElement.className = 'hack-result ' + (success ? 'hack-success' : 'hack-failure');
    resultElement.style.display = 'block';
    
    post({
        type: 'hackResult',
        success: success
    });
    
    setTimeout(() => {
        const hackInterface = document.getElementById('hacking-interface');
        hackInterface.style.display = 'none';
        
        document.querySelectorAll('.hack-circle').forEach((circle, index) => {
            circle.innerHTML = '';
            if (index > 0) {
                circle.style.display = 'none';
            }
        });
        
        resultElement.style.display = 'none';
        hackingActive = false;
        currentStage = 0;
        progressValue = 0;
    }, 3000);
}

function triggerHackFromLua() {
    startHoldPhase();
}

if (typeof window !== 'undefined') {
    window.addEventListener('DOMContentLoaded', function() {
        window.addEventListener('message', function(event) {
            const data = event.data;
            
            if (data.type === 'showCameraUI') {
                document.getElementById('cameraSystem').style.display = 'block';
                document.getElementById('cameraId').textContent = 'CAM_' + data.cameraId.toString().padStart(2, '0');
                
                updateDateTime();
                
                document.getElementById('cameraSystem').classList.add('visible');
            } else if (data.type === 'hideCameraUI') {
                document.getElementById('cameraSystem').classList.remove('visible');
                setTimeout(() => {
                    document.getElementById('cameraSystem').style.display = 'none';
                }, 500);
            } else if (data.type === 'showInteractionPrompt') {
                const prompt = document.getElementById('interactionPrompt');
                document.getElementById('interactionText').textContent = data.message;
                prompt.style.display = 'block';
                prompt.classList.add('visible');
            } else if (data.type === 'hideInteractionPrompt') {
                const prompt = document.getElementById('interactionPrompt');
                prompt.classList.remove('visible');
                setTimeout(() => {
                    prompt.style.display = 'none';
                }, 500);
            } else if (data.type === 'showNotification') {
                showNotification(data.message, data.style);
            }
        });
    });
}

function handleMessage(data) {
    if (!data || !data.type) return;
    
    switch(data.type) {
        case 'showCameraUI':
            showCameraUI(data);
            break;
        case 'hideCameraUI':
            hideCameraUI();
            break;
        case 'updateCamera':
            updateCameraInfo(data);
            break;
        case 'showInteractionPrompt':
            showInteractionPrompt(data.message);
            break;
        case 'hideInteractionPrompt':
            hideInteractionPrompt();
            break;
        case 'showNotification':
            showNotification(data.message, data.style);
            break;
        case 'updateZoom':
            updateZoomIndicator(data.zoom);
            break;
        case 'setViewMode':
            setViewMode(data.mode);
            break;
    }
}

function showCameraUI(data) {
    currentViewMode = 'normal';
    
    const cameraModeElement = document.getElementById('camera-mode');
    if (cameraModeElement) {
        cameraModeElement.textContent = `Mode: ${currentViewMode.toUpperCase()}`;
    }
    
    console.log('Showing camera UI with camera ID:', data.cameraId);
    
    const cameraSystem = document.getElementById('cameraSystem');
    if (!cameraSystem) return;
    
    cameraSystem.style.display = 'block';
    
    if (data.cameraId) {  // camera ID
        document.getElementById('cameraId').textContent = 'CAM_' + data.cameraId.toString().padStart(2, '0');
    }
    
    updateDateTime(); // should add ability to change time format e.g. DD/MM/YYYY or MM/DD/YYYY
    
    setTimeout(() => {
        cameraSystem.classList.add('visible');
    }, 10);
}

function hideCameraUI() {
    console.log('Hiding camera UI');
    
    const cameraSystem = document.getElementById('cameraSystem');
    if (!cameraSystem) return;
    
    cameraSystem.classList.remove('visible');
    
    setTimeout(() => {
        cameraSystem.style.display = 'none';
    }, 500);
}

function updateCameraInfo(data) {
    if (data.cameraId) {
        const cameraIdElement = document.getElementById('cameraId');
        if (cameraIdElement) {
            cameraIdElement.textContent = `CAM_${data.cameraId.toString().padStart(2, '0')}`;
        }
    }
    
    if (data.cameraName) {
        const cameraNameElement = document.getElementById('camera-name');
        if (cameraNameElement) {
            cameraNameElement.textContent = data.cameraName.toUpperCase();
        }
    }
    
    if (data.location) {
        const locationElement = document.getElementById('camera-location');
        if (locationElement) {
            locationElement.textContent = data.location.toUpperCase();
        }
    }
    
    const modeElement = document.getElementById('camera-mode');
    if (modeElement) {
        modeElement.textContent = `MODE: ${currentViewMode.toUpperCase()}`;
    }
}

function showInteractionPrompt(message) {
    const prompt = document.querySelector('.interaction-prompt');
    if (!prompt) return;
    
    prompt.textContent = message;
    prompt.classList.add('visible');
}

function hideInteractionPrompt() {
    const prompt = document.querySelector('.interaction-prompt');
    if (!prompt) return;
    
    prompt.classList.remove('visible');
}

function showNotification(message, style) {
    if (notificationTimeout) {
        clearTimeout(notificationTimeout);
    }
    
    const notification = document.querySelector('.notification');
    if (!notification) return;
    
    notification.textContent = message;
    notification.className = 'notification';
    notification.classList.add(style || 'success');
    notification.classList.add('visible');
    
    notificationTimeout = setTimeout(() => {
        notification.classList.remove('visible');
    }, 5000);
}

function updateZoomIndicator(zoom) {
    const zoomIndicator = document.querySelector('.zoom-indicator');
    if (!zoomIndicator) return;
    
    zoomIndicator.textContent = `Zoom: ${Math.round(zoom * 100)}%`;
}

function updateDateTime() {
    const dateTime = document.querySelector('.date-time');
    if (!dateTime) return;
    
    const now = new Date();
    const date = now.toLocaleDateString();
    const time = now.toLocaleTimeString();
    
    dateTime.textContent = `${date} ${time}`;
}

function updateControlsHelp(controls) {
    const controlsList = document.querySelector('.controls-help ul');
    if (!controlsList) return;
    
    controlsList.innerHTML = '';
    
    for (const [action, key] of Object.entries(controls)) {
        const li = document.createElement('li');
        li.innerHTML = `<span class="key">${key}</span> ${action}`;
        controlsList.appendChild(li);
    }
}

function createCameraUI() {
    const cameraContainer = document.createElement('div');
    cameraContainer.className = 'camera-container';
    
    // camera overlay
    const overlay = document.createElement('div');
    overlay.className = 'camera-overlay';
    cameraContainer.appendChild(overlay);
    
    // scan lines effect
    const scanLines = document.createElement('div');
    scanLines.className = 'scan-lines';
    cameraContainer.appendChild(scanLines);
    
    // camera info
    const cameraInfo = document.createElement('div');
    cameraInfo.className = 'camera-info';
    cameraInfo.innerHTML = `
        <div class="camera-name">Camera 1</div>
        <div class="camera-id">ID: CAM-001</div>
        <div class="date-time">00/00/0000 00:00:00</div>
    `;
    cameraContainer.appendChild(cameraInfo);
    
    // recording indicator
    const recordingIndicator = document.createElement('div');
    recordingIndicator.className = 'recording-indicator';
    cameraContainer.appendChild(recordingIndicator);
    
    // controls help
    const controlsHelp = document.createElement('div');
    controlsHelp.className = 'controls-help';
    controlsHelp.innerHTML = `
        <h3>Controls</h3>
        <ul>
            <li><span class="key">↑↓←→</span> Move camera</li> 
            <li><span class="key">E</span> Interact</li>
            <li><span class="key">ESC</span> Exit</li>
        </ul>
    `;
    cameraContainer.appendChild(controlsHelp);
    
    // zoom indicator
    const zoomIndicator = document.createElement('div');
    zoomIndicator.className = 'zoom-indicator';
    zoomIndicator.textContent = 'Zoom: 100%';
    cameraContainer.appendChild(zoomIndicator);
    
    // interaction prompt
    const interactionPrompt = document.createElement('div');
    interactionPrompt.className = 'interaction-prompt';
    interactionPrompt.textContent = 'Press E to hack';
    cameraContainer.appendChild(interactionPrompt);
    
    // notification
    const notification = document.createElement('div');
    notification.className = 'notification';
    cameraContainer.appendChild(notification);
    
    document.body.appendChild(cameraContainer);
}

function updateDateTime() {
    const now = new Date();
    document.getElementById('timestamp').textContent = now.toLocaleTimeString();
    document.getElementById('date').textContent = now.toLocaleDateString();
}

function showNotification(message, style) {
    const notif = document.getElementById('notification');
    const notifText = document.getElementById('notificationText');
    
    notifText.textContent = message;
    notif.className = 'notification';
    if (style) notif.classList.add(style);
    
    notif.style.display = 'block';
    
    setTimeout(() => {
        notif.classList.add('visible');
    }, 100);
    
    setTimeout(() => {
        notif.classList.remove('visible');
        setTimeout(() => {
            notif.style.display = 'none';
        }, 500);
    }, 3000);
}

setInterval(updateDateTime, 1000);

const markerContainer = document.getElementById('marker-container');
let markers = {};
window.isActive = window.isActive || false;

window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'setReticleState':
            if (data.state !== currentReticleState) {
                currentReticleState = data.state;
                handleReticleState(data);
            }
            break;
            
        case 'setInteractableProp':
            interactablePropInView = data.prop;
            console.log("Interactable prop set:", interactablePropInView);
            break;
            
        case 'setActive':
            window.isActive = data.active;
            if (!window.isActive) {
                clearAllMarkers();
            }
            break;
        case 'createMarker':
            createMarker(data.id, data.screenX, data.screenY, data.label);
            break;
        case 'updateMarker':
            updateMarker(data.id, data.screenX, data.screenY);
            break;
        case 'removeMarker':
            removeMarker(data.id);
            break;
        case 'clearMarkers':
            clearAllMarkers();
            break;
        case 'setViewMode':
            setViewMode(data.mode);
            break;
        case 'updateCameraInfo':
            updateCameraInfo(data);
            break;
    }
});

function handleReticleState(data) { // this handles the reticle state changes
    const reticle = document.querySelector('.camera-reticle');
    const existingTargeting = document.getElementById('targeting-indicator');
    
    console.log("Setting reticle state to: " + data.state);
    
    if (data.state === 'targeting') {
        if (!existingTargeting) {
            const targetingIndicator = document.createElement('div');
            targetingIndicator.id = 'targeting-indicator';
            
            const scanRing = document.createElement('div');
            scanRing.className = 'scan-ring';
            
            const cornerTL = document.createElement('div');
            cornerTL.className = 'targeting-corner corner-top-left';
            
            const cornerTR = document.createElement('div');
            cornerTR.className = 'targeting-corner corner-top-right';
            
            const cornerBL = document.createElement('div');
            cornerBL.className = 'targeting-corner corner-bottom-left';
            
            const cornerBR = document.createElement('div');
            cornerBR.className = 'targeting-corner corner-bottom-right';
            
            const targetText = document.createElement('div');
            targetText.className = 'target-text';
            targetText.textContent = 'TARGET IDENTIFIED';
            
            targetingIndicator.appendChild(scanRing);
            targetingIndicator.appendChild(cornerTL);
            targetingIndicator.appendChild(cornerTR);
            targetingIndicator.appendChild(cornerBL);
            targetingIndicator.appendChild(cornerBR);
            targetingIndicator.appendChild(targetText);
            
            if (reticle) {
                reticle.appendChild(targetingIndicator);
                
                setTimeout(() => {
                    targetingIndicator.classList.add('active');
                }, 10);
            }
        }
    } else {
        if (existingTargeting) {
            existingTargeting.classList.remove('active');
            
            setTimeout(() => {
                if (existingTargeting.parentNode) {
                    existingTargeting.parentNode.removeChild(existingTargeting);
                }
            }, 500);
        }
    }
}

function createMarker(id, x, y, label = '') { // does the marker creation and animation
    if (!window.isActive) return;

    if (!markers[id]) {
        const markerDiv = document.createElement('div');
        markerDiv.className = 'marker';
        markerDiv.id = `marker-${id}`;

        const xMarker = document.createElement('div');
        xMarker.className = 'x-marker';
        markerDiv.appendChild(xMarker);

        if (label) {
            const labelDiv = document.createElement('div');
            labelDiv.className = 'highlight-label';
            labelDiv.textContent = label;
            markerDiv.appendChild(labelDiv);
        }

        markerContainer.appendChild(markerDiv);
        markers[id] = markerDiv;

        animateMarker(xMarker);
    }

    updateMarker(id, x, y);
}

function updateMarker(id, x, y) {
    const marker = markers[id];
    if (marker) {
        marker.style.left = `${x}px`;
        marker.style.top = `${y}px`;
    }
}

function removeMarker(id) {
    if (markers[id]) {
        markerContainer.removeChild(markers[id]);
        delete markers[id];
    }
}

function clearAllMarkers() {
    Object.keys(markers).forEach(id => {
        markerContainer.removeChild(markers[id]);
    });
    markers = {};
}

function animateMarker(element) { // spins like a pendulum :)
    element.animate([
        { transform: 'rotate(0deg) scale(1)' },
        { transform: 'rotate(360deg) scale(1.2)' }
    ], {
        duration: 1000,
        easing: 'cubic-bezier(0.5, 0, 0.5, 1)',
        fill: 'forwards'
    }).onfinish = () => {
        element.animate([
            { transform: 'rotate(360deg) scale(1.2)' },
            { transform: 'rotate(0deg) scale(1)' }
        ], {
            duration: 1200,
            easing: 'cubic-bezier(0.1, 0.7, 0.1, 1)',
            fill: 'forwards'
        });
    };
}

function post(data) {
    fetch(`https://${GetParentResourceName()}/callback`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    });
}

// not currently working
document.addEventListener('keydown', function(event) {
    if (!window.isActive) return;
    
    if (event.keyCode === 81) {
        console.log('Q key pressed, toggling view mode');

        const nextMode = {
            'normal': 'thermal',
            'thermal': 'nightvision',
            'nightvision': 'normal'
        }[currentViewMode] || 'normal';
        
        setViewMode(nextMode);
    }
});

function setViewMode(mode) {
    console.log('Setting view mode to:', mode);
    currentViewMode = mode;
    
    const cameraModeElement = document.getElementById('camera-mode');
    if (cameraModeElement) {
        cameraModeElement.textContent = `MODE: ${mode.toUpperCase()}`;
    }
    
    post({
        type: 'setViewMode',
        mode: currentViewMode
    });
    
    const modeNames = {
        'normal': 'Normal View',
        'thermal': 'Thermal Vision',
        'nightvision': 'Night Vision'
    };
    
    showNotification(`Switched to ${modeNames[mode]}`, 'info');
}

window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {        
        case 'updateCameraInfo':
            updateCameraInfo(data);
            break;
            
        case 'setViewMode':
            setViewMode(data.mode);
            break;
    }
});

function setViewMode(mode) {
    console.log('Setting view mode to:', mode);
    currentViewMode = mode;
    
    const cameraModeElement = document.getElementById('camera-mode');
    if (cameraModeElement) {
        cameraModeElement.textContent = `Mode: ${mode.toUpperCase()}`;
    }
    
    post({
        type: 'setViewMode',
        mode: currentViewMode
    });
    
    const modeNames = {
        'normal': 'Normal View',
        'thermal': 'Thermal Vision',
        'nightvision': 'Night Vision'
    };
    
    showNotification(`Switched to ${modeNames[mode]}`, 'info');
}

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.type === 'showCameraUI') {
        window.isActive = true;
    } else if (data.type === 'hideCameraUI') {
        window.isActive = false;
    }
    
    if (data.type === 'setViewMode') {
        setViewMode(data.mode);
    }
    
    if (data.type === 'updateCameraInfo') {
        if (data.cameraName) {
            const nameElement = document.getElementById('camera-name');
            if (nameElement) nameElement.textContent = `Name: ${data.cameraName}`;
        }
        
        if (data.location) {
            const locationElement = document.getElementById('camera-location');
            if (locationElement) locationElement.textContent = `Location: ${data.location}`;
        }
        
        const modeElement = document.getElementById('camera-mode');
        if (modeElement) modeElement.textContent = `Mode: ${currentViewMode.toUpperCase()}`;
    }
});