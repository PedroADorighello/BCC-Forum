import firebase_admin
from firebase_admin import credentials, firestore, auth
from collections import defaultdict

cred = credentials.Certificate('firebase-key.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

def gerar_ranking_alunos():
    print("Varrendo as avaliações no Firestore...\n")
    
    contagem_por_uid = defaultdict(int)
    
    todas_avaliacoes = db.collection_group('avaliacoes').stream()
    
    total_avaliacoes = 0
    for avaliacao in todas_avaliacoes:
        dados = avaliacao.to_dict()
        uid = avaliacao.id 
        contagem_por_uid[uid] += 1
        total_avaliacoes += 1

        if uid == 'COLOCAR_UID_DE_TESTE_AQUI':  # Substitua pelo UID de um aluno específico para ver detalhes
            id_da_materia = avaliacao.reference.parent.parent.id
            texto = dados.get('comentario', 'SEM TEXTO')
            print(f"Sua avaliação na matéria [{id_da_materia}]: '{texto}'")

    print(f"Foram encontradas {total_avaliacoes} avaliações feitas por {len(contagem_por_uid)} alunos diferentes.\n")
    print("Cruzando UIDs com E-mails do Firebase Auth...\n")

    ranking = []
    
    for uid, contagem in contagem_por_uid.items():
        try:
            user_record = auth.get_user(uid)
            email = user_record.email
        except Exception:
            email = f"Conta Excluída (UID: {uid})"
            
        ranking.append({
            'email': email,
            'quantidade': contagem
        })

    ranking.sort(key=lambda x: x['quantidade'], reverse=True)

    print("RANKING DE ENGAJAMENTO DOS ALUNOS")
    print("=" * 50)
    for posicao, aluno in enumerate(ranking, start=1):
        medalha = "🥇" if posicao == 1 else "🥈" if posicao == 2 else "🥉" if posicao == 3 else "  "
        print(f"{medalha} {posicao}º lugar | {aluno['quantidade']:02d} avaliações | {aluno['email']}")
    print("=" * 50)

if __name__ == '__main__':
    gerar_ranking_alunos()