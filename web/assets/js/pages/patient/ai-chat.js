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

    return text || rawText || "Xin chào! Bạn có thể cho tôi biết triệu chứng hiện tại để tôi tư vấn nhé.";
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
    time.textContent = 'Vừa xong';
    
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
                finalReply = "Xin hãy tiếp tục chia sẻ triệu chứng của bạn để tôi có thể hỗ trợ nhé.";
            }

            addMessage(finalReply, 'incoming');
            if (symptoms) updateHealthSummary({ symptoms });

            if (data.reachedLimit) {
                chatInput.disabled = true;
                chatInput.placeholder = "Đã đạt giới hạn tin nhắn.";
                const btnSend = chatForm.querySelector('.btn-send');
                if (btnSend) btnSend.disabled = true;
            }
        } else {
            addMessage("Hệ thống đang bị quá tải. Vui lòng thử lại sau.", 'incoming');
        }
    } catch (error) {
        console.error("Chat error:", error);
        if (document.getElementById('typingIndicator')) {
            document.getElementById('typingIndicator').remove();
        }
        addMessage("Không thể kết nối với máy chủ. Vui lòng kiểm tra mạng.", 'incoming');
    }
});

// Nút "Tạo hồ sơ" → lưu triệu chứng + lịch sử chat vào AI_Summary
function submitHealthRecordFromChat() {
    const symptoms = document.getElementById('chatSymptoms').value.trim();

    const chatMessages = [];
    document.querySelectorAll('.message').forEach(msg => {
        const content = msg.querySelector('.message-bubble');
        if (content) {
            const sender = msg.classList.contains('outgoing') ? 'Bệnh nhân' : 'AI';
            chatMessages.push(`${sender}: ${(content.textContent || content.innerText).trim()}`);
        }
    });
    const chatHistory = chatMessages.join('\n');

    if (!chatHistory) {
        alert('Chưa có nội dung cuộc trò chuyện để lưu.');
        return;
    }

    if (!confirm('Bạn có chắc muốn lưu tóm tắt triệu chứng này? AI sẽ tổng hợp cuộc trò chuyện và lưu vào hồ sơ.')) {
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
            alert('Tóm tắt triệu chứng đã được lưu thành công!');
            location.reload();
        } else {
            alert('Lỗi: ' + (data.error || 'Không thể lưu'));
        }
    })
    .catch(err => {
        console.error('Submit error:', err);
        alert('Lỗi kết nối. Vui lòng thử lại.');
    });
}
