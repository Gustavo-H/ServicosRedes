CREATE DATABASE padariaBD 

USE padariaBD; 

CREATE TABLE produtos (
    codigo INT NOT NULL AUTO_INCREMENT,
    nomeProduto VARCHAR(70),
    preco FLOAT,
    PRIMARY KEY(codigo)
);

INSERT INTO produtos (nomeProduto, preco) VALUES ('Pão de Sal', 0.50);
INSERT INTO produtos (nomeProduto, preco) VALUES ('Pudim', 5.00); 
INSERT INTO produtos (nomeProduto, preco) VALUES ('Queijo Minas', 15.00);
INSERT INTO produtos (nomeProduto, preco) VALUES ('Presunto', 2.50);
INSERT INTO produtos (nomeProduto, preco) VALUES ('Carburador Fusca Completo', 70.00);
INSERT INTO produtos (nomeProduto, preco) VALUES ('Kit 4 Velas Fiat Uno', 20.00);


