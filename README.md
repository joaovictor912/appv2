# Corretor de Gabaritos AI (Versão Cliente-Servidor)

Um aplicativo móvel, construído com Flutter, que se conecta a um backend inteligente em Python para corrigir provas de múltipla escolha de forma automática, usando apenas a câmera do celular.

## Sobre o Projeto

Este projeto foi desenvolvido para auxiliar educadores e professores a otimizar o tempo gasto na correção de provas. O aplicativo permite gerenciar turmas, alunos e provas, e realiza a correção automática de gabaritos a partir de uma foto, fornecendo a nota final instantaneamente.

Esta versão do projeto utiliza uma arquitetura cliente-servidor, onde o aplicativo Flutter é responsável pela interface do usuário e captura da imagem, enquanto um servidor Python robusto, hospedado na nuvem, executa todo o processamento pesado de Visão Computacional e Inteligência Artificial.

## Funcionalidades Principais

* **Gerenciamento Completo:** Crie e gerencie Turmas, Alunos e Provas.
* **Gabarito Mestre:** Cadastre o gabarito oficial para cada prova diretamente no app.
* **Correção por Câmera:** Utilize a câmera para tirar uma foto da folha de respostas do aluno.
* **Análise Remota:** A imagem é enviada para um servidor que realiza a análise e retorna o resultado.
* **Resultados Imediatos:** Veja a nota do aluno, acertos e erros logo após a análise.
* **Histórico de Correções:** Todas as correções ficam salvas e associadas ao aluno e à prova correspondente.
* **Autenticação Segura:** Login e gerenciamento de usuários com Firebase Authentication.

## Tecnologias Utilizadas

Este projeto é dividido em duas partes principais: o frontend (aplicativo) e o backend (servidor de análise).

### Frontend (Aplicativo Móvel)

* **Framework:** Flutter
* **Linguagem:** Dart
* **Comunicação HTTP:** Pacote `http` para se comunicar com o backend.
* **Banco de Dados Local:** `sqflite` para persistência de dados no dispositivo.
* **Autenticação:** `firebase_auth`
* **Câmera:** `camera`

### Backend (Servidor de Análise)

* **Framework:** Flask
* **Linguagem:** Python
* **Processamento de Imagem:** `opencv-python` e `imutils` para manipulação de imagem, detecção de contornos e correção de perspectiva.
* **Plataforma de IA:** Roboflow para treinamento e hospedagem dos modelos de IA.
* **Hospedagem:** Render (ou outra plataforma de hospedagem de serviços web).
* **Modelos de IA:**
    1.  **Detector de Gabarito:** Um modelo de detecção de objetos treinado no Roboflow para encontrar a localização e os 4 cantos da folha de respostas na imagem.
    2.  **Classificador de Bolhas:** Um modelo de classificação treinado no Roboflow para identificar se uma bolha individual está "marcada" ou "vazia".

## Arquitetura e Fluxo de Análise

O sistema opera em uma arquitetura cliente-servidor, onde as responsabilidades são claramente divididas.

1.  **Captura (Flutter):** O usuário tira a foto do gabarito no aplicativo.
2.  **Requisição (Flutter):** O app envia a imagem para um endpoint específico (`/analisar_prova`) no servidor Python via uma requisição HTTP POST.
3.  **Processamento no Backend (Python):** O servidor executa uma pipeline de Visão Computacional robusta:
    * **Detecção da Folha (IA - Roboflow):** O primeiro modelo de IA é chamado para encontrar os 4 cantos do gabarito na imagem.
    * **Correção de Perspectiva (OpenCV):** A função `four_point_transform` "desentorta" a imagem, criando uma visão perfeitamente retangular, como se fosse escaneada.
    * **Detecção das Bolhas (OpenCV):** Na imagem alinhada, `cv2.findContours` identifica todas as bolhas, que são filtradas por tamanho e proporção.
    * **Leitura das Respostas (Lógica Híbrida):** Para cada questão (grupo de 5 bolhas), o sistema executa um processo otimizado:
        * **"Competição" Matemática:** O OpenCV mede a "densidade" de pixels pretos em cada uma das 5 bolhas. A bolha mais "escura" é eleita a candidata mais provável.
        * **Veredito Final (IA - Classificador):** Apenas a imagem da bolha candidata é enviada para o segundo modelo de IA do Roboflow, que dá o veredito final, confirmando se ela está de fato "marcada".
4.  **Resposta (Python):** O servidor monta um objeto JSON com as respostas do aluno (ex: `{"1": "C", "2": "A", "3": "N/A"}`) e o retorna para o aplicativo.
5.  **Exibição (Flutter):** O app recebe o JSON, o decodifica e o utiliza para calcular a nota e exibir os resultados na `TelaResultado`.

## Como Executar o Projeto

### Backend (Servidor Python)

1.  **Clone o repositório do backend.**
2.  **Instale as dependências:**
    ```bash
    pip install Flask opencv-python numpy imutils roboflow
    ```
3.  **Configure suas chaves:** Preencha as variáveis de API KEY, Workspace ID e nomes dos projetos do Roboflow no topo do script `app.py`.
4.  **Execute o servidor localmente:**
    ```bash
    python app.py
    ```
5.  Para produção, faça o deploy deste script em uma plataforma como o Render.
