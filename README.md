# conecta_servidores
Script utilizado para conectar em uma lista de servidores e executar comandos conforme o arquivo armazenando na variável LISTA_COMANDOS

## Utilizando
Pré requisito
Ter um servidor com a chave publica instalada em todos os servidores da lista.

### Validando o funcionamento do SSH  
1 - Baixa o script para o servidor que tem a chave SSH compartilhada  

2 - Criar um arquivo com o seguinte nome  
```touch servidores-linux.csv```

3- Adicionar todos os servidores linux BRQ, seguindo o padrão de preenchimento  
NOME,STATUS,IP,SO  
Ex:  
srv17621,Ativo,10.2.1.163,Ubuntu  

Atenção: No processo de troca de chave SSH a lista de servidores não pode conter o próprio servidor linux que executará o script, caso contrário ele apagará as próprias chaves SSH.  
  
4 - Testar o script de conexão no servidor  
descomentar a linha  
LISTA_COMANDOS=/etc/scripts/conecta_servidores/comandos-teste-ssh  

5 - Executar o script e verificar o resultado  
```./conecta_servidores.sh```  
Esse comando criar uma pasta com o nome de 1 no diretorio /tmp  

Exemplo de saída
[ OK ] CI:srv5024 C:ssh -p 22 -i /root/.ssh-20170620/id_rsa root@10.2.1.154 touch /tmp/1  
[ IGNORADO ] CI:srv3041 C:ssh -p 0 -i /root/.ssh-20170620/id_rsa root@10.2.1.152 touch /tmp/1  
[ FALHA ] CI:srv5023 C:ssh -p 22 -i /root/.ssh-20170620/id_rsa root@10.2.1.153 touch /tmp/1  

OK = Tudo funcionou conforme esperado  
IGNORADO = Sistema operacional diferente não linux  
FALHA = houve uma falha no acesso ou na criação do arquivo, necessário verificar  
 
Após validar todos os servidores podemos seguir com a troca da chave SSH.  

### Trocando da chave SSH em lote   
1 - Fazer backup da chave publica atual usuário root e brqssh  
```
cp -rp /root/.ssh /root/.ssh-backup  
cp -rp /home/brqssh/.ssh /home/brqssh/.ssh-backup  
```

2 - Limpar o diretório SSH do root (tenha certeza que o backup esteja funcionando)  
```
rm -f /root/.ssh/id*  
rm -f /root/.ssh/authorized*  
```

3 - Gerar novas chave SSH
```ssh-keygen -b 1024 -t rsa && cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys  ```

4 - No script conecta-servidor.sh descomentar a linha para copiar a chave publica  
LISTA_COMANDOS=/etc/scripts/conecta_servidores/comandos-copia-chave  

5 - Executar o script para copiar a nova chave  
```./conecta_servidores.sh ``` 

6 - Testar conectar SSH em um servidor  
6.1 - Usando a chave nova  
```ssh -p 22 10.2.1.163  ```
6.2 - Usando a chave antiga  
```ssh -p 22 -i /root/.ssh-backup/id_rsa 10.2.1.163 ``` 

Ambos os comandos devem conectar no servidor  

7 - Limpar as chaves SSH antiga de todos os servidores  
No script conecta-servidor.sh comente a linha  
LISTA_COMANDOS=/etc/scripts/conecta_servidores/comandos-copia-chave  
Descomentar a linha  
LISTA_COMANDOS=/etc/scripts/conecta_servidores/comandos-limpa-chave  

8 - Executar o script para para limpar as chaves antigas  
./conecta_servidores.sh  

9 - Testar conectar SSH em um servidor  
9.1 - Usando a chave nova  
```ssh -p 22 10.2.1.163 ```
9.2 - Usando a chave antiga  
```ssh -p 22 -i /root/.ssh-backup/id_rsa 10.2.1.163```  

Apenas o primeiro deve funcionar, levando em conta que a chave antiga foram removidas  

Lembrando que após esse procedimento, devemos replicar esse chave para o servidor de vpnautomatica.  

### Processo de Fallback  
Caso ocorra algum problema com a nova chave ssh basta restaurar o backup  

1 - Fazer backup da nova chave SSH  
```
cp -rp /root/.ssh /root/.ssh-backup\-$DATA  
cp -rp /home/brqssh/.ssh /home/brqssh/.ssh-backup\-$DATA  
```

2 - Limpar as chaves atuais  

```
rm -f /root/.ssh/id*  
rm -f /root/.ssh/authorized*  
```

3 - Restaurar o backup  
```
cp -rp /root/.ssh-backup/* /root/.ssh  
cp -rp /home/brqssh/.ssh-backup/* /home/brqssh/.ssh  
```

---

#### Método antigo e manual

Objetivo:  
Alterar a chave publica de vários servidores usuário root e brqssh  
Compartilhar essa chave publica com os mesmo servidores  
Tornar a chave publica do root igual para o usuario brqssh  

1 - Conectar no servidor que tenha a chave SSH configurada  

1.5 - Fazer backup do diretorio ssh  

```
cp -r /root/.ssh /root/old.ssh
```

2 - Limpar arquivos de configuração SSH  
```rm /root/.ssh/id*  
rm /root/.ssh/authorized* 
```

3 - Gerar nova chave SSH  
```ssh-keygen -b 1024 -t rsa ``` 

4 - Copiar chave para proprio servidor  
```cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys2  ```

5 - Limpar configuracoes do usuario brqssh  
```rm /home/brqssh/.ssh/*  ```

6 - Copiar chaves do root para brqssh local  
```
cp -r ~/.ssh/* /home/brqssh/.ssh  
chown brqssh:brqssh /home/brqssh/.ssh/*
```  

7 - Testar conexão ssh do usuário root para o usuário brqssh  
```ssh brqssh@10.2.40.200 ``` 

8 - Criar lista de servidores para compartilhas as chaves  
```vim lista-servidores-ips  ```

Conteudo  
```
10.2.65.189  
192.168.200.15  
10.200.1.23  
10.200.1.17  
10.2.40.200  
10.2.249.254  
10.2.89.200  
10.2.8.240  
10.200.1.12  
10.2.1.199 
```

9 - Copiar chaves para usuários root  
```
for i in `cat lista-servidores-ips`; do scp -p -P 2222  ~/.ssh/* root@$i:/root/.ssh; done; 
``` 

10 - Copiar chaves para usuário brqssh  
```
for i in `cat lista-servidores-ips`; do scp -p -P 2222  /home/brqssh/.ssh/* root@$i:/home/brqssh/.ssh; done; 
```
