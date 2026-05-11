# RoterizaTrack - Mini Roteirizador de Entregas

Este é um sistema simplificado de roteirização de entregas, desenvolvido como parte de um teste técnico para Desenvolvedor Junior. O projeto utiliza uma arquitetura de microserviços totalmente conteinerizada.

## 🚀 Arquitetura

O sistema é composto por três serviços principais:

1.  **Management Service (Ruby on Rails)**:
    *   API RESTful para gestão de Endereços, Veículos e Motoristas.
    *   Persistência: PostgreSQL.
    *   Utiliza UUIDs para identificação de recursos.

2.  **Routing Service (Node.js + TypeScript)**:
    *   API RESTful para processamento e cálculo de rotas.
    *   **Endpoint `/rotas/calcular`**: Ordena endereços com base em coordenadas (Latitude/Longitude).
    *   **Endpoint `/rotas/atribuir`**: Atualiza o status dos endereços no Management Service via chamadas HTTP internas.

3.  **Frontend (Vue 3 + TypeScript)**:
    *   SPA moderna construída com Vite.
    *   Interface premium com design focado em UX (Glassmorphism, Micro-animações).
    *   Permite a seleção de endereços e veículos, visualização de rotas sugeridas e atribuição de rotas.

## 🛠️ Tecnologias Utilizadas

*   **Backend**: Ruby on Rails, Node.js, Express, TypeScript.
*   **Frontend**: Vue 3, Vite, Lucide Icons.
*   **Banco de Dados**: PostgreSQL (Instâncias isoladas para cada serviço).
*   **Infraestrutura**: Docker, Docker Compose.

## 📦 Como Rodar a Aplicação

Certifique-se de ter o **Docker** e o **Docker Compose** instalados em sua máquina.

1.  Clone o repositório.
2.  Na raiz do projeto, execute o comando:
    ```bash
    docker-compose up --build
    ```
3.  O Docker Compose irá:
    *   Subir os bancos de dados PostgreSQL.
    *   Compilar as imagens dos microserviços.
    *   Rodar as migrações e o seed do banco de dados (Management Service).
4.  Acesse as aplicações:
    *   **Frontend**: [http://localhost:5173](http://localhost:5173)
    *   **Management API**: [http://localhost:3000](http://localhost:3000)
    *   **Routing API**: [http://localhost:3001](http://localhost:3001)

## 📝 Decisões Técnicas

*   **Comunicação**: O Frontend consome ambos os serviços. O Routing Service comunica-se internamente com o Management Service usando o nome do host do container (`http://management-service:3000`).
*   **CORS**: Configurado em ambos os backends para permitir a comunicação com o frontend.
*   **Design**: Optei por um design escuro (Dark Mode) com gradientes modernos para proporcionar uma experiência de usuário premium.
*   **Lógica de Rota**: Implementada uma lógica simples de ordenação por coordenadas geográficas para demonstrar a manipulação de dados e integração entre serviços.

## 🚀 Melhorias Futuras

*   Implementação de testes unitários e de integração (RSpec/Jest).
*   Integração com APIs reais de mapas (Leaflet/Google Maps).
*   Algoritmos de otimização de rota mais complexos (Problema do Caixeiro Viajante).
*   Autenticação e Autorização (JWT).
