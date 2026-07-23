const chatWindow = document.getElementById('chatWindow');
const chatForm = document.getElementById('chatForm');
const chatInput = document.getElementById('chatInput');

const endpoint = window.ApiClient.buildUrl('/ai-chat');

const cleanAiReply = (value) => {
    let rawText = String(value || '').trim();
    let text = rawText;

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

    return text || rawText || "Xin ch\u00e0o! B\u1ea1n c\u00f3 th\u1ec3 cho t\u00f4i bi\u1ebft tri\u1ec7u ch\u1ee9ng hi\u1ec7n t\u1ea1i \u0111\u1ec3 t\u00f4i t\u01b0 v\u1ea5n nh\u00e9.";
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

// Chỉ cập nhật ô Triệu chứng
const updateHealthSummary = (data) => {
    if (!data) return;
    if (data.symptoms !== undefined && data.symptoms !== "" && data.symptoms !== "0") {
        const symptomsEl = document.getElementById('chatSymptoms');
        const current = symptomsEl.value.trim();
        if (current && !current.includes(data.symptoms)) {
            symptomsEl.value = current + ', ' + data.symptoms;
        } else if (!current) {
            symptomsEl.value = data.symptoms;
        }
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
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
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
                try { data = JSON.parse(jsonMatch[0]); } catch (e2) {}
            }
        }
        
        if (document.getElementById('typingIndicator')) {
            document.getElementById('typingIndicator').remove();
        }
        
        if (data) {
            let finalReply = data.reply;
            let symptoms = data.symptoms;

            if (!finalReply || typeof finalReply !== 'string' || !finalReply.trim()) {
                finalReply = "Xin h\u00e3y ti\u1ebfp t\u1ee5c chia s\u1ebb tri\u1ec7u ch\u1ee9ng c\u1ee7a b\u1ea1n \u0111\u1ec3 t\u00f4i c\u00f3 th\u1ec3 h\u1ed7 tr\u1ee3 nh\u00e9.";
            }

            addMessage(finalReply, 'incoming');
            if (symptoms) updateHealthSummary({ symptoms });

            if (data.reachedLimit) {
                chatInput.disabled = true;
                chatInput.placeholder = "\u0110\u00e3 \u0111\u1ea1t gi\u1edbi h\u1ea1n tin nh\u1eafn.";
                const btnSend = chatForm.querySelector('.btn-send');
                if (btnSend) btnSend.disabled = true;
            }
        } else {
            addMessage("H\u1ec7 th\u1ed1ng \u0111ang b\u1ecb qu\u00e1 t\u1ea3i. Vui l\u00f2ng th\u1eed l\u1ea1i sau.", 'incoming');
        }
    } catch (error) {
        console.error("Chat error:", error);
        if (document.getElementById('typingIndicator')) {
            document.getElementById('typingIndicator').remove();
        }
        addMessage("Kh\u00f4ng th\u1ec3 k\u1ebft n\u1ed1i v\u1edbi m\u00e1y ch\u1ee7. Vui l\u00f2ng ki\u1ec3m tra m\u1ea1ng.", 'incoming');
    }
});

// Nút "Tạo hồ sơ" → lưu triệu chứng + lịch sử chat vào AI_Summary
function submitHealthRecordFromChat() {
    const symptoms = document.getElementById('chatSymptoms').value.trim();

    const chatMessages = [];
    document.querySelectorAll('.message').forEach(msg => {
        const content = msg.querySelector('.message-bubble');
        if (content) {
            const sender = msg.classList.contains('outgoing') ? 'B\u1ec7nh nh\u00e2n' : 'AI';
            chatMessages.push(`${sender}: ${(content.textContent || content.innerText).trim()}`);
        }
    });
    const chatHistory = chatMessages.join('\n');

    if (!chatHistory) {
        alert('Ch\u01b0a c\u00f3 n\u1ed9i dung cu\u1ed9c tr\u00f2 chuy\u1ec7n \u0111\u1ec3 l\u01b0u.');
        return;
    }

    if (!confirm('B\u1ea1n c\u00f3 ch\u1eafc mu\u1ed1n l\u01b0u t\u00f3m t\u1eaft tri\u1ec7u ch\u1ee9ng n\u00e0y? AI s\u1ebd t\u1ed5ng h\u1ee3p cu\u1ed9c tr\u00f2 chuy\u1ec7n v\u00e0 l\u01b0u v\u00e0o h\u1ed3 s\u01a1.')) {
        return;
    }

    const params = new URLSearchParams();
    params.append('action', 'finish');
    if (symptoms) params.append('symptoms', symptoms);
    if (chatHistory) params.append('chatHistory', chatHistory);

    fetch(endpoint, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
    })
    .then(r => r.json())
    .then(data => {
        if (data.success) {
            alert('T\u00f3m t\u1eaft tri\u1ec7u ch\u1ee9ng \u0111\u00e3 \u0111\u01b0\u1ee3c l\u01b0u th\u00e0nh c\u00f4ng!');
            location.reload();
        } else {
            alert('L\u1ed7i: ' + (data.error || 'Kh\u00f4ng th\u1ec3 l\u01b0u'));
        }
    })
    .catch(err => {
        console.error('Submit error:', err);
        alert('L\u1ed7i k\u1ebft n\u1ed1i. Vui l\u00f2ng th\u1eed l\u1ea1i.');
    });
}
