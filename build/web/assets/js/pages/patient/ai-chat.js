(function () {
    const chatWindow = document.getElementById("chatWindow");
    const chatForm = document.getElementById("chatForm");
    const chatInput = document.getElementById("chatInput");
    const finishButton = document.getElementById("finishChatButton");
    const endpoint = ApiClient.buildUrl("/ai-chat");
    const appointmentId = Number(new URLSearchParams(window.location.search).get("appointmentId"));
    let conversationId = null;

    function addMessage(text, type) {
        const message = document.createElement("div");
        message.className = `message ${type}`;

        const avatar = document.createElement("div");
        avatar.className = `message-avatar ${type === "incoming" ? "ai" : "user"}`;
        if (type === "incoming") {
            const icon = document.createElement("i");
            icon.className = "bi bi-robot";
            avatar.append(icon);
        } else {
            avatar.textContent = "U";
        }

        const content = document.createElement("div");
        content.className = "message-content";

        const bubble = document.createElement("div");
        bubble.className = "message-bubble";
        bubble.textContent = text;

        const time = document.createElement("div");
        time.className = "message-time";
        time.textContent = "V\u1EEBa xong";

        content.append(bubble, time);
        message.append(avatar, content);
        chatWindow.append(message);
        chatWindow.scrollTop = chatWindow.scrollHeight;
    }

    function showTypingIndicator() {
        const indicator = document.createElement("div");
        indicator.className = "message incoming";
        indicator.id = "typingIndicator";
        indicator.innerHTML = `
            <div class="message-avatar ai"><i class="bi bi-robot"></i></div>
            <div class="message-content">
                <div class="typing-indicator">
                    <div class="typing-dots"><span></span><span></span><span></span></div>
                </div>
            </div>
        `;
        chatWindow.append(indicator);
        chatWindow.scrollTop = chatWindow.scrollHeight;
    }

    function removeTypingIndicator() {
        document.getElementById("typingIndicator")?.remove();
    }

    function extractReply(responseText) {
        const data = JSON.parse(responseText.trim());
        if (typeof data.reply !== "string") {
            throw new Error("Ph\u1EA3n h\u1ED3i AI kh\u00F4ng \u0111\u00FAng c\u1EA5u tr\u00FAc.");
        }

        const nestedReply = data.reply.trim();
        if (!nestedReply.startsWith("{")) {
            return data.reply;
        }

        try {
            const nestedData = JSON.parse(nestedReply);
            return nestedData.reply || data.reply;
        } catch (error) {
            return data.reply;
        }
    }

    async function loadAppointmentConversation() {
        if (!Number.isInteger(appointmentId) || appointmentId <= 0) {
            return;
        }

        finishButton.hidden = false;
        try {
            const appointmentData = await ApiClient.get(
                    `/patient/api/appointments?id=${appointmentId}`);
            conversationId = appointmentData.appointment.conversationId;
            if (!conversationId) {
                return;
            }

            const conversation = await ApiClient.get(
                    `/ai-conversation?id=${conversationId}`);
            if (!conversation.messages?.length) {
                return;
            }

            chatWindow.replaceChildren();
            conversation.messages.forEach((message) => {
                addMessage(message.message, message.sender === "user" ? "outgoing" : "incoming");
            });
            if (conversation.summary) {
                addMessage(`T\u00F3m t\u1EAFt \u0111\u00E3 l\u01B0u: ${conversation.summary}`, "incoming");
            }
        } catch (error) {
            console.error("Unable to load appointment conversation:", error);
            addMessage("Kh\u00F4ng th\u1EC3 t\u1EA3i l\u1EA1i l\u1ECBch s\u1EED tr\u00F2 chuy\u1EC7n c\u1EE7a l\u1ECBch h\u1EB9n.", "incoming");
        }
    }

    chatForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const message = chatInput.value.trim();
        if (!message) return;

        addMessage(message, "outgoing");
        chatInput.value = "";
        chatInput.disabled = true;
        showTypingIndicator();

        try {
            const response = await fetch(endpoint, {
                method: "POST",
                credentials: "same-origin",
                headers: { "Content-Type": "application/x-www-form-urlencoded" },
                body: new URLSearchParams({
                    message,
                    ...(Number.isInteger(appointmentId) && appointmentId > 0
                        ? { appointmentId: String(appointmentId) } : {})
                }).toString()
            });

            const responseText = await response.text();
            if (!response.ok) {
                throw new Error(`M\u00E1y ch\u1EE7 tr\u1EA3 v\u1EC1 l\u1ED7i HTTP ${response.status}.`);
            }

            const data = JSON.parse(responseText.trim());
            conversationId = data.conversationId || conversationId;
            addMessage(data.reply || extractReply(responseText), "incoming");
        } catch (error) {
            console.error("Chat error:", error);
            addMessage("Kh\u00F4ng th\u1EC3 nh\u1EADn ph\u1EA3n h\u1ED3i t\u1EEB AI. Vui l\u00F2ng th\u1EED l\u1EA1i.", "incoming");
        } finally {
            removeTypingIndicator();
            chatInput.disabled = false;
            chatInput.focus();
        }
    });

    finishButton.addEventListener("click", async () => {
        if (!Number.isInteger(appointmentId) || appointmentId <= 0) {
            return;
        }

        finishButton.disabled = true;
        chatInput.disabled = true;
        showTypingIndicator();
        try {
            const data = await ApiClient.postForm("/ai-chat", new URLSearchParams({
                action: "finish",
                appointmentId: String(appointmentId)
            }));
            addMessage(`T\u00F3m t\u1EAFt cho b\u00E1c s\u0129: ${data.summary}`, "incoming");
            finishButton.textContent = "\u0110\u00E3 t\u1EA1o t\u00F3m t\u1EAFt";
        } catch (error) {
            addMessage(`Kh\u00F4ng th\u1EC3 t\u1EA1o t\u00F3m t\u1EAFt: ${error.message}`, "incoming");
            finishButton.disabled = false;
        } finally {
            removeTypingIndicator();
            chatInput.disabled = false;
        }
    });

    loadAppointmentConversation();
})();
