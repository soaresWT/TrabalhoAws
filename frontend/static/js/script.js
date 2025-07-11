// Configuração da API
const API_BASE_URL = window.location.origin;

// Elementos DOM
const enviarForm = document.getElementById("enviarCartaForm");
const cartasContainer = document.getElementById("cartasContainer");
const cartaModal = document.getElementById("cartaModal");
const nomeDestinatarioInput = document.getElementById("nomeDestinatario");

// Inicialização
document.addEventListener("DOMContentLoaded", function () {
  initializeEventListeners();
});

// Event Listeners
function initializeEventListeners() {
  // Formulário de envio
  enviarForm.addEventListener("submit", enviarCarta);

  // Enter no campo de busca
  nomeDestinatarioInput.addEventListener("keypress", function (e) {
    if (e.key === "Enter") {
      buscarCartas();
    }
  });

  // Fechar modal com ESC
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") {
      fecharModal();
    }
  });

  // Fechar modal clicando fora
  cartaModal.addEventListener("click", function (e) {
    if (e.target === cartaModal) {
      fecharModal();
    }
  });
}

// Função para trocar tabs
function showTab(tabName) {
  // Remover classe active de todos os botões e conteúdos
  document
    .querySelectorAll(".tab-button")
    .forEach((btn) => btn.classList.remove("active"));
  document
    .querySelectorAll(".tab-content")
    .forEach((content) => content.classList.remove("active"));

  // Adicionar classe active ao botão e conteúdo selecionados
  event.target.classList.add("active");
  document.getElementById(tabName).classList.add("active");
}

// Função para enviar carta
async function enviarCarta(e) {
  e.preventDefault();

  const formData = new FormData(enviarForm);
  const cartaData = {
    remetente: formData.get("remetente"),
    destinatario: formData.get("destinatario"),
    titulo: formData.get("titulo"),
    conteudo: formData.get("conteudo"),
  };

  // Validação básica
  if (
    !cartaData.remetente ||
    !cartaData.destinatario ||
    !cartaData.titulo ||
    !cartaData.conteudo
  ) {
    showNotification("Por favor, preencha todos os campos!", "error");
    return;
  }

  try {
    // Desabilitar botão durante o envio
    const submitBtn = enviarForm.querySelector('button[type="submit"]');
    const originalText = submitBtn.innerHTML;
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Enviando...';

    const response = await fetch(`${API_BASE_URL}/api/cartas`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(cartaData),
    });

    const result = await response.json();

    if (response.ok) {
      showNotification("Carta enviada com sucesso! 💕", "success");
      enviarForm.reset();

      // Adicionar efeito de confete (opcional)
      createHeartAnimation();
    } else {
      showNotification(result.error || "Erro ao enviar carta", "error");
    }
  } catch (error) {
    console.error("Erro:", error);
    showNotification("Erro de conexão. Tente novamente.", "error");
  } finally {
    // Reabilitar botão
    const submitBtn = enviarForm.querySelector('button[type="submit"]');
    submitBtn.disabled = false;
    submitBtn.innerHTML = originalText;
  }
}

// Função para buscar cartas
async function buscarCartas() {
  const destinatario = nomeDestinatarioInput.value.trim();

  if (!destinatario) {
    showNotification("Digite seu nome para buscar suas cartas", "error");
    return;
  }

  try {
    // Mostrar loading
    cartasContainer.innerHTML = `
            <div class="loading">
                <i class="fas fa-heart fa-spin" style="font-size: 2rem; color: #ff6b6b;"></i>
                <p>Procurando suas cartas de amor...</p>
            </div>
        `;

    const response = await fetch(
      `${API_BASE_URL}/api/cartas/${encodeURIComponent(destinatario)}`
    );
    const cartas = await response.json();

    if (response.ok) {
      exibirCartas(cartas);
    } else {
      showNotification(cartas.error || "Erro ao buscar cartas", "error");
      cartasContainer.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-exclamation-triangle"></i>
                    <p>Erro ao carregar suas cartas</p>
                </div>
            `;
    }
  } catch (error) {
    console.error("Erro:", error);
    showNotification("Erro de conexão. Tente novamente.", "error");
    cartasContainer.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-wifi"></i>
                <p>Problema de conexão</p>
            </div>
        `;
  }
}

// Função para exibir cartas
function exibirCartas(cartas) {
  if (cartas.length === 0) {
    cartasContainer.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-heart-broken"></i>
                <p>Nenhuma carta encontrada ainda...</p>
                <p>Que tal pedir para alguém especial te enviar uma? 💕</p>
            </div>
        `;
    return;
  }

  cartasContainer.innerHTML = cartas
    .map(
      (carta) => `
        <div class="carta-item ${
          !carta.lida ? "nao-lida" : ""
        }" onclick="abrirCarta(${carta.id})">
            <div class="carta-header">
                <div class="carta-titulo">${escapeHtml(carta.titulo)}</div>
                <div class="carta-data">${formatarData(carta.data_envio)}</div>
            </div>
            <div class="carta-remetente">
                <i class="fas fa-heart"></i>
                De: ${escapeHtml(carta.remetente)}
            </div>
            <div class="carta-preview">
                ${escapeHtml(carta.conteudo.substring(0, 150))}${
        carta.conteudo.length > 150 ? "..." : ""
      }
            </div>
        </div>
    `
    )
    .join("");
}

// Função para abrir carta no modal
async function abrirCarta(cartaId) {
  try {
    // Buscar dados atualizados da carta
    const destinatario = nomeDestinatarioInput.value.trim();
    const response = await fetch(
      `${API_BASE_URL}/api/cartas/${encodeURIComponent(destinatario)}`
    );
    const cartas = await response.json();

    const carta = cartas.find((c) => c.id === cartaId);

    if (!carta) {
      showNotification("Carta não encontrada", "error");
      return;
    }

    // Marcar como lida se não estava
    if (!carta.lida) {
      await marcarComoLida(cartaId);
    }

    // Exibir carta no modal
    document.getElementById("cartaDetalhes").innerHTML = `
            <div class="carta-completa">
                <h2 class="carta-titulo-completo">${escapeHtml(
                  carta.titulo
                )}</h2>
                <div class="carta-meta">
                    <div><strong>De:</strong> ${escapeHtml(
                      carta.remetente
                    )}</div>
                    <div><strong>Para:</strong> ${escapeHtml(
                      carta.destinatario
                    )}</div>
                    <div><strong>Data:</strong> ${formatarData(
                      carta.data_envio
                    )}</div>
                </div>
                <div class="carta-conteudo-completo">${escapeHtml(
                  carta.conteudo
                )}</div>
            </div>
        `;

    cartaModal.style.display = "block";

    // Atualizar a lista de cartas para refletir que foi lida
    setTimeout(() => {
      buscarCartas();
    }, 500);
  } catch (error) {
    console.error("Erro ao abrir carta:", error);
    showNotification("Erro ao abrir carta", "error");
  }
}

// Função para marcar carta como lida
async function marcarComoLida(cartaId) {
  try {
    await fetch(`${API_BASE_URL}/api/cartas/${cartaId}/ler`, {
      method: "PUT",
    });
  } catch (error) {
    console.error("Erro ao marcar como lida:", error);
  }
}

// Função para fechar modal
function fecharModal() {
  cartaModal.style.display = "none";
}

// Função para mostrar notificações
function showNotification(message, type = "success") {
  const notification = document.getElementById("notification");
  notification.textContent = message;
  notification.className = `notification ${type}`;
  notification.classList.add("show");

  setTimeout(() => {
    notification.classList.remove("show");
  }, 4000);
}

// Função para formatar data
function formatarData(dataISO) {
  const data = new Date(dataISO);
  const options = {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  };
  return data.toLocaleDateString("pt-BR", options);
}

// Função para escapar HTML (segurança)
function escapeHtml(unsafe) {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// Animação de corações (efeito especial ao enviar carta)
function createHeartAnimation() {
  for (let i = 0; i < 20; i++) {
    setTimeout(() => {
      const heart = document.createElement("div");
      heart.innerHTML = "💕";
      heart.style.position = "fixed";
      heart.style.left = Math.random() * window.innerWidth + "px";
      heart.style.top = window.innerHeight + "px";
      heart.style.fontSize = "20px";
      heart.style.pointerEvents = "none";
      heart.style.zIndex = "9999";
      heart.style.transition = "all 3s ease-out";

      document.body.appendChild(heart);

      setTimeout(() => {
        heart.style.top = "-50px";
        heart.style.opacity = "0";
      }, 100);

      setTimeout(() => {
        document.body.removeChild(heart);
      }, 3100);
    }, i * 200);
  }
}

// Verificar conexão com a API
async function checkAPIConnection() {
  try {
    const response = await fetch(`${API_BASE_URL}/api/health`);
    if (!response.ok) {
      throw new Error("API não respondeu");
    }
  } catch (error) {
    console.error("Erro de conexão com a API:", error);
    showNotification("Problema de conexão com o servidor", "error");
  }
}

// Verificar conexão quando a página carrega
document.addEventListener("DOMContentLoaded", function () {
  setTimeout(checkAPIConnection, 1000);
});
