import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

cred = credentials.Certificate("firebase-key.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

print("Procurando os comentários mais recentes...\n")

try:
    avaliacoes = db.collection_group('avaliacoes')\
                   .order_by('timestamp', direction=firestore.Query.DESCENDING)\
                   .limit(15)\
                   .stream()

    lista_comentarios = []

    for index, doc in enumerate(avaliacoes):
        dados = doc.to_dict()
        
        if 'comentario' in dados and dados['comentario'].strip():
            materia_id = doc.reference.parent.parent.id
            texto = dados['comentario']
            
            lista_comentarios.append({
                'ref': doc.reference,
                'materia': materia_id,
            })
            
            print(f"[{index}] Disciplina: {materia_id}")
            print(f"    Comentário: \"{texto}\"")
            print("-" * 50)

    if not lista_comentarios:
        print("Nenhum comentário com texto foi encontrado.")
    else:
        print("\nO que deseja fazer?")
        escolha = input("Digite o NÚMERO do comentário para APAGAR (ou pressione Enter para sair): ")
        
        if escolha.isdigit() and 0 <= int(escolha) < len(lista_comentarios):
            alvo = lista_comentarios[int(escolha)]
            
            alvo['ref'].update({'comentario': firestore.DELETE_FIELD})
            
            print(f"\nO comentário na disciplina '{alvo['materia']}' foi apagado com sucesso!")
            print("As notas de dificuldade e qualidade do aluno foram mantidas.")
        else:
            print("\nNenhuma ação realizada. Saindo...")

except Exception as e:
    print(f"\nErro ao procurar dados: {e}")