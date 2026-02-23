# 🎓 Fórum de Avaliações - BCC UFSCar

Uma plataforma colaborativa desenvolvida para os estudantes de Ciência da Computação da Universidade Federal de São Carlos (UFSCar - Sorocaba). O fórum permite que os alunos avaliem, comentem e visualizem o nível de dificuldade e qualidade das disciplinas da grade curricular oficial.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

## ✨ Funcionalidades

* **Autenticação Institucional:** Acesso restrito via Firebase Auth apenas para e-mails com o domínio `@estudante.ufscar.br` e `@ufscar.br`.
* **Voto Único e Transações Atômicas:** Sistema que garante apenas uma avaliação por aluno por disciplina, permitindo a edição do voto e recalculando a média de forma atômica no Firestore.
* **Filtros e Pesquisa em Tempo Real:** Pesquisa client-side otimizada e filtros por categoria da matriz curricular (Obrigatória, Optativa 1 e Optativa 2).
* **Moderação Ativa:** Script administrativo em Python para varredura e exclusão de comentários impróprios, mantendo a integridade das notas.

## 🏗️ Arquitetura e Segurança

A aplicação utiliza o **Firebase Firestore** como banco de dados NoSQL. Para contornar as limitações de leitura e manter o custo do banco gratuito, a arquitetura foi desenhada utilizando **Subcoleções**:

* `materias/{materiaId}` -> Contém a soma total de notas, contador de votos e metadados.
* `materias/{materiaId}/avaliacoes/{userId}` -> Contém o voto individual e comentário de cada aluno.

As **Regras de Segurança (Security Rules)** foram configuradas para bloquear acesso anônimo de escrita e autorizar consultas profundas de `CollectionGroup` de forma segura.

## 🚀 Como executar o projeto localmente

### Pré-requisitos
* [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado (versão `stable`).
* Uma conta no Firebase com um projeto configurado (Auth e Firestore).

### Passos
1. Clone o repositório:
   ```bash
   git clone https://github.com/PedroADorighello/BCC-Forum.git
   ```
2. Acesse a pasta do projeto e instale as dependências:
   ```bash
   cd nome_da_pasta
   flutter pub get
   ```
3. Execute o projeto no Chrome (Web):
   ```bash
   flutter run -d chrome
   ```
## 🛠️ Scripts Administrativos (Pasta ```/admin```)

O projeto conta com scripts em Python para administração do banco de dados:
* ```sync_materias.py```: Lê o arquivo ```materias.txt``` contendo a grade curricular e sincroniza com o Firestore (cria novas e faz soft delete das antigas).
* ```moderar_comentarios.py```: Varre as subcoleções globalmente buscando os últimos comentários para moderação rápida via terminal.
* ```ranking_alunos.py```: Monta um ranking via terminal dos alunos que mais contribuíram com avaliações no fórum.

(Nota: É necessário gerar uma Service Account Key no Firebase e salvá-la como ```firebase-key.json``` na pasta ```/admin``` para executar os scripts).

## 🔄 CI/CD (Deploy Automatizado)

Este projeto utiliza GitHub Actions para Integração e Entrega Contínuas.

Ao realizar um push para a branch main, o pipeline realiza automaticamente o setup do ambiente Flutter, compila a aplicação Web e faz o deploy direto para o Firebase Hosting.

----

Desenvolvido por Pedro.