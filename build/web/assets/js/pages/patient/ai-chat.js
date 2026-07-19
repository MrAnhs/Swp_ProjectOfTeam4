const chatWindow = document.getElementById('chatWindow');
const chatForm = document.getElementById('chatForm');
const chatInput = document.getElementById('chatInput');

const endpoint = window.ApiClient.buildUrl('/ai-chat');

const cleanAiReply = (value) => {
    let text = String(value || '').trim();

    // Unwrap valid nested JSON before applying display-only cleanup.
    for (let i = 0; i < 2 && text.startsWith('{'); i++) {
        try {
            const nested = JSON.parse(text);
            if (typeof nested.reply !== 'string') break;
            text = nested.reply.trim();
        } catch (error) {
            break;
        }
    }

    text = text
        .replace(/^```(?:json)?\s*/i, '')
        .replace(/\s*```$/i, '')
        .replace(/^\s*\{\s*"reply"\s*:\s*"/i, '')
        .replace(/"\s*,?\s*"healthData"\s*:[\s\S]*$/i, '')
        .replace(/"\s*\}\s*$/i, '')
        .replace(/\\n/g, '\n')
        .replace(/\\r/g, '')
        .replace(/\\t/g, ' ')
        .replace(/\*\*/g, '')
        .replace(/__/g, '')
        .replace(/`/g, '')
        .split('\n')
        .map(line => line.replace(/\\+\s*$/, '').trimEnd())
        .join('\n')
        .replace(/\n{3,}/g, '\n\n')
        .trim();

    return text;
};

const addMessage = (text, type = 'incoming') => {
    const message = document.createElement('div');
    message.className = `message ${type}`;
    
    const avatar = document.createElement('div');
    avatar.className = `message-avatar ${type === 'incoming' ? 'ai' : 'user'}`;
    avatar.innerHTML = type === 'incoming' ? '<i class="bi bi-robot"></i>' : 'U';
    
    const content = document.createElement('div');
    content.className = 'message-content';
    
    const bubble = document.createElement('div');
    bubble.className = 'message-bubble';

    bubble.textContent = type === 'incoming' ? cleanAiReply(text) : String(text || '').trim();
    
    const time = document.createElement('div');
    time.className = 'message-time';
    time.textContent = 'V\u1eeba xong';
    
    content.appendChild(bubble);
    content.appendChild(time);
    
    message.appendChild(avatar);
    message.appendChild(content);
    
    chatWindow.appendChild(message);
    chatWindow.scrollTop = chatWindow.scrollHeight;
};

const updateHealthSummary = (data) => {
    if (!data) return;

    if (data.urea !== undefined && data.urea !== 0) {
        document.getElementById('chatUrea').value = data.urea;
    }
    if (data.cr !== undefined && data.cr !== 0) {
        document.getElementById('chatCr').value = data.cr;
    }
    if (data.hba1c !== undefined && data.hba1c !== 0) {
        document.getElementById('chatHba1c').value = data.hba1c;
    }
    if (data.chol !== undefined && data.chol !== 0) {
        document.getElementById('chatChol').value = data.chol;
    }
    if (data.tg !== undefined && data.tg !== 0) {
        document.getElementById('chatTg').value = data.tg;
    }
    if (data.hdl !== undefined && data.hdl !== 0) {
        document.getElementById('chatHdl').value = data.hdl;
    }
    if (data.ldl !== undefined && data.ldl !== 0) {
        document.getElementById('chatLdl').value = data.ldl;
    }
    if (data.vldl !== undefined && data.vldl !== 0) {
        document.getElementById('chatVldl').value = data.vldl;
    }
    if (data.weight !== undefined && data.weight !== 0) {
        document.getElementById('chatWeight').value = data.weight;
    }
    if (data.height !== undefined && data.height !== 0) {
        document.getElementById('chatHeight').value = data.height;
    }
    if (data.symptoms !== undefined && data.symptoms !== "" && data.symptoms !== "0") {
        document.getElementById('chatSymptoms').value = data.symptoms;
    }
};

chatForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    const text = chatInput.value.trim();
    if (!text) return;
    
    addMessage(text, 'outgoing');
    chatInput.value = '';

    const typingIndicator = document.createElement('div');
    typingIndicator.className = 'message incoming';
    typingIndicator.id = 'typingIndicator';
    typingIndicator.innerHTML = `
        <div class="message-avatar ai"><i class="bi bi-robot"></i></div>
        <div class="message-content">
            <div class="typing-indicator">
                <div class="typing-dots">
                    <span></span><span></span><span></span>
                </div>
            </div>
        </div>
    `;
    chatWindow.appendChild(typingIndicator);
    chatWindow.scrollTop = chatWindow.scrollHeight;

    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: `message=${encodeURIComponent(text)}`,
        });
        
        const responseText = await response.text();
        console.log("Raw Response from Servlet:", responseText);
        
        let data;
        try {
            data = JSON.parse(responseText.trim());
        } catch (e) {
            console.error("Initial JSON Parse Error:", e);
            const jsonMatch = responseText.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                try {
                    data = JSON.parse(jsonMatch[0]);
                } catch (e2) {
                    console.error("Regex JSON Parse Error:", e2);
                }
            }
        }
        
        if(document.getElementById('typingIndicator')) document.getElementById('typingIndicator').remove();
        
        if (data) {
            let finalReply = data.reply;
            let healthData = data.healthData;

            if (typeof finalReply === 'string' && finalReply.trim().startsWith('{')) {
                try {
                    const nestedData = JSON.parse(finalReply);
                    if (nestedData.reply) {
                        finalReply = nestedData.reply;
                        if (nestedData.healthData) healthData = nestedData.healthData;
                    }
                } catch (e) {}
            }

            if (finalReply) {
                addMessage(finalReply, 'incoming');
                if (healthData) updateHealthSummary(healthData);
                if (data.reachedLimit) {
                    chatInput.disabled = true;
                    chatInput.placeholder = "\u0110\u00e3 \u0111\u1ea1t gi\u1edbi h\u1ea1n tin nh\u1eafn. Vui l\u00f2ng t\u1ea1o h\u1ed3 s\u01a1.";
                    const btnSend = chatForm.querySelector('.btn-send');
                    if (btnSend) btnSend.disabled = true;
                }
            } else {
                addMessage("Xin l\u1ed7i, AI tr\u1ea3 v\u1ec1 d\u1eef li\u1ec7u kh\u00f4ng \u0111\u00fang c\u1ea5u tr\u00fac.", 'incoming');
            }
        } else {
            addMessage("L\u1ed7i c\u1ea5u tr\u00fac d\u1eef li\u1ec7u t\u1eeb m\u00e1y ch\u1ee7. Vui l\u00f2ng th\u1eed l\u1ea1i.", 'incoming');
        }
    } catch (error) {
        console.error("Chat error:", error);
        if(document.getElementById('typingIndicator')) document.getElementById('typingIndicator').remove();
        addMessage("Kh\u00f4ng th\u1ec3 k\u1ebft n\u1ed1i v\u1edbi m\u00e1y ch\u1ee7. Vui l\u00f2ng ki\u1ec3m tra m\u1ea1ng.", 'incoming');
    }
});

function submitHealthRecordFromChat() {
    const healthData = {
        urea: document.getElementById('chatUrea').value,
        creatinine: document.getElementById('chatCr').value,
        hba1c: document.getElementById('chatHba1c').value,
        cholesterol: document.getElementById('chatChol').value,
        tg: document.getElementById('chatTg').value,
        hdl: document.getElementById('chatHdl').value,
        ldl: document.getElementById('chatLdl').value,
        vldl: document.getElementById('chatVldl').value,
        weight: document.getElementById('chatWeight').value,
        height: document.getElementById('chatHeight').value,
        symptoms: document.getElementById('chatSymptoms').value
    };

    const chatMessages = [];
    const messageElements = document.querySelectorAll('.message');
    messageElements.forEach(msg => {
        const content = msg.querySelector('.message-bubble');
        const isOutgoing = msg.classList.contains('outgoing');
        
        if (content) {
            const sender = isOutgoing ? 'Patient' : 'AI';
            const text = content.textContent || content.innerText;
            chatMessages.push(`${sender}: ${text.trim()}`);
        }
    });
    
    const chatHistory = chatMessages.join('\n');

    if (!confirm('B\u1ea1n c\u00f3 ch\u1eafc mu\u1ed1n g\u1eedi h\u1ed3 s\u01a1 s\u1ee9c kh\u1ecfe n\u00e0y? Sau khi g\u1eedi, cu\u1ed9c tr\u00f2 chuy\u1ec7n v\u1edbi AI s\u1ebd k\u1ebft th\u00fac v\u00e0 \u0111\u01b0\u1ee3c l\u01b0u v\u00e0o l\u1ecbch s\u1eed.')) {
        return;
    }

    const params = new URLSearchParams();
    for (const [key, value] of Object.entries(healthData)) {
        if (value) params.append(key, value);
    }
    params.append('chatHistory', chatHistory);

    fetch(window.ApiClient.buildUrl('/submit-health-record'), {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
    })
    .then(r => r.json())
    .then(data => {
        if (data.success) {
            alert('H\u1ed3 s\u01a1 s\u1ee9c kh\u1ecfe \u0111\u00e3 \u0111\u01b0\u1ee3c g\u1eedi th\u00e0nh c\u00f4ng!');
            window.location.href = window.ApiClient.buildUrl(`/patient/health-records/detail?id=${data.healthRecordId}`);
        } else {
            alert('L\u1ed7i: ' + (data.error || 'Kh\u00f4ng th\u1ec3 g\u1eedi h\u1ed3 s\u01a1'));
        }
    })
    .catch(err => {
        console.error('Error submitting health record:', err);
        alert('L\u1ed7i k\u1ebft n\u1ed1i. Vui l\u00f2ng th\u1eed l\u1ea1i.');
    });
}
