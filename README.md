# RoterizaTrack - Sistema de Roteirização Logística

Uma plataforma conteinerizada de gestão de frota e roteirização inteligente de entregas. O RoterizaTrack permite que operações logísticas organizem endereços pendentes, visualizem-os geograficamente no mapa e calculem a melhor rota otimizada para seus veículos, simulando em tempo real o trajeto da entrega.

## 🚀 Setup com Docker Compose

O projeto foi inteiramente desenhado para rodar em containers Docker, tornando sua inicialização extremamente simples em qualquer sistema operacional.

**Pré-requisitos**:
- [Docker](https://docs.docker.com/get-docker/) instalado.
- [Docker Compose](https://docs.docker.com/compose/install/) instalado.

**Instruções Claras de Setup**:
1. Clone este repositório para a sua máquina local.
2. Na raiz do projeto, abra seu terminal e execute o comando de inicialização:
   ```bash
   docker-compose up --build
   ```
3. O Docker fará o download das imagens, instalará dependências (Gems e NPM) e iniciará os bancos de dados. Aguarde o Docker finalizar a construção das imagens e o aviso de que as APIs estão online.
   *(Nota: As migrations do banco do Management Service e o processo de seed que preenche os dados iniciais rodarão de forma automática no boot)*.
4. Acesse a aplicação no seu navegador:
   - **Frontend (Interface do Usuário)**: [http://localhost:5173](http://localhost:5173) 
     *(Para entrar, utilize `admin@roterizatrack.com` com a senha `password123` ou crie uma nova conta clicando em "Criar conta")*.
   - **Management API (Backend Rails)**: `http://localhost:3000`
   - **Routing API (Backend Node.js)**: `http://localhost:3001`

## 🛠️ Decisões de Design e Escolhas Técnicas Relevantes

- **Arquitetura de Microserviços**: O projeto é dividido em um serviço principal de gestão de entidades e usuários em **Ruby on Rails** (trazendo o padrão de modelagem ActiveRecord e segurança inerente do Rails), e um microsserviço veloz e escalável dedicado apenas para os cálculos de rotas feito em **Node.js com TypeScript** e Express.
- **Segurança com JWT**: As rotas e requisições do sistema são protegidas com JSON Web Tokens (JWT). Apenas usuários autenticados via Login conseguem ler, criar endereços ou ordenar veículos.
- **Integração Real de Mapeamento Geográfico**: O front usa `Leaflet.js` debaixo dos panos para um rendering customizado e leve, integrado às APIs abertas `OpenStreetMap (Nominatim)` para geocodificação de Endereço/CEP para Lat/Lon, e `OSRM (Open Source Routing Machine)` para desenhar a geometria (polígono) literal do caminho no asfalto.
- **Algoritmo de Otimização no Backend**: O backend (`routing-service`) possui heurísticas como *"Multi-Start Nearest Neighbor"* combinada com o refinamento *"2-opt"*, rodando as aproximações por distâncias puras (Fórmula de Haversine) para entregar o trajeto mais rápido possível, poupando as requisições à API pública de mapa.
- **Design de Interface Premium (Aesthetics)**: O Frontend utiliza **Vue.js 3** e componentes customizados sem frameworks engessados. A atenção especial foi dada à UX e UI com Glassmorphism, temas visuais (Dark/Light mode via CSS Variables), grid maps fluidos e micro-animações state-of-the-art para dar a sensação de um SaaS de excelência.
- **Persistência de Cachê e Redes Docker**: Para que a tela não perca a geometria ao atualizar, o microserviço Node salva a string GeoJSON num BD e é listada pelas chamadas do frontend, tornando-se imune à limite de taxas do OSM. Ambos os microsserviços se comunicam internamente na mesma rede docker.

## 🚀 Melhorias Futuras (Opcional)

- **Comunicação em Tempo Real via WebSockets**: Migrar de consultas via REST/pooling para uma integração com ActionCable ou Socket.io que reflete o andamento da entrega (simulação do caminhão) instantaneamente para todos os gestores logados.
- **Testes Abrangentes**: Ampliar a suíte de testes com RSpec no backend e testes end-to-end com Cypress no Vue.js.
- **Tolerância a Falhas**: Implementar "Circuit Breakers" na comunicação com as APIs públicas gratuitas (ViaCEP/OSRM/Nominatim). Se por ventura os serviços deles saírem do ar, o sistema utilizará um fallback 100% off-line (linhas retas).
