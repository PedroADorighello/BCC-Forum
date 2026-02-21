import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(cred)

db = firestore.client()
colecao_materias = db.collection('materias')

disciplinas_txt = {}
with open('materias.txt', 'r', encoding='utf-8') as arquivo:
    for linha in arquivo:
        if linha.strip():
            partes = linha.split('&')
            nome = partes[0].strip()
            categoria = partes[1].strip() if len(partes) > 1 else "Obrigatória"
            disciplinas_txt[nome] = categoria

docs_firebase = colecao_materias.stream()
banco_dados = {doc.id: doc.to_dict() for doc in docs_firebase}

for nome, categoria in disciplinas_txt.items():
    if nome not in banco_dados:
        colecao_materias.document(nome).set({
            'nome': nome,
            'categoria': categoria,
            'votos': 0,
            'soma_dificuldade': 0.0,
            'soma_avaliacao': 0.0,
            'ativo': True
        })
        print(f"Adicionada: {nome} ({categoria})")
    else:
        colecao_materias.document(nome).update({
            'ativo': True,
            'categoria': categoria
        })
        print(f"Atualizada/Reativada: {nome} ({categoria})")

for nome_banco, dados in banco_dados.items():
    if nome_banco not in disciplinas_txt and dados.get('ativo', True):
        colecao_materias.document(nome_banco).update({'ativo': False})
        print(f"Ocultada: {nome_banco}")

print("Sincronização completa!")