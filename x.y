%{
#include <stdio.h>
#include <string.h>
#include "defs.h"
#define INDENT_LENGTH 4
#define LINE_WIDTH 80

int yylex(void); 
int yyerror(const char *txt); 
int level=0,pos=0;
enum typ_znacznika{
	otwierajacy = 0,
	konczacy = 1,
	pusty = 2
};
void sprawdz_znaczniki(const char* z1,const char* z2);
void wypisz_znaczniki(const char* z1,int z2);
void wypisz_ip(const char* ip);
void lamanie_tekstu(void);
void indent(void); // korzysta ze zmiennej globalnej level
int tekst = 0;
int ignoruj_biale_po=1;
%}
%define parse.error verbose
%union {
  char s[MAXSTRLEN+1];
}

%token <s> PI_TAG_BEG PI_TAG_END STAG_BEG ETAG_BEG TAG_END ETAG_END CHAR S; 

%type <s> start_tag end_tag word;

%%

 /* Dokument XML sklada sie ze wstepu i elementu*/
DOKUMENT: WSTEP ELEMENT '\n';

 /*Wstep sklada sie z ciagu instrukcji przetwarzania i znakow nowego wiersza*/
WSTEP: INSTRUKCJA_PRZETWARZANIA | '\n' | WSTEP '\n' | WSTEP INSTRUKCJA_PRZETWARZANIA;

/* Instrukcja przetwarzania sklada sie z poczatku instrukcji przetwarzania (PI_TAG_BEG) i konca tej instrukcji (PI_TAG_END).*/;
INSTRUKCJA_PRZETWARZANIA: PI_TAG_BEG PI_TAG_END { 
	indent(); // Instrukcja przetwarzania pojawia sie we wstepie wiec poziom zagniezdzenia bedzie rowny 0
	wypisz_ip($1); 
};

 /*Element sklada sie z pustego znacznika lub z pary elementow*/
ELEMENT: PUSTY_ZNACZNIK | PARA_ZNACZNIKOW ;

 /*Pusty znacznik sklada sie z poczatku znacznika (STAG_BEG) i konca pustego znacznika (ETAG_END)*/
PUSTY_ZNACZNIK: STAG_BEG ETAG_END{ wypisz_znaczniki($1,pusty); };
 /*Para znacznikow sklada sie ze znacznika otwierajacego, zawartosci i znacznika konczacego.*/
PARA_ZNACZNIKOW: start_tag ZAWARTOSC end_tag { tekst = 0; sprawdz_znaczniki($1,$3); };

 /*Znacznik otwierajacy sklada sie z poczatku znacznika (STAG_BEG) i konca znacznika (TAG_END)*/
start_tag: STAG_BEG TAG_END { wypisz_znaczniki($1,otwierajacy); level++; pos=INDENT_LENGTH*level; ignoruj_biale_po=0;};

 /*Znacznik konczacy sklada sie ze znacznika konczacego (ETAG_BEG) i konca znacznika (TAG_END)*/
end_tag: ETAG_BEG TAG_END { 
	if(tekst==1) printf("\n");
	level--; 
	wypisz_znaczniki($1,konczacy);
	pos=INDENT_LENGTH*level;
	ignoruj_biale_po=1;
};

 /*Zawartosc jest ciagiem elementow, bialych znakow (S), slow (ciagow znakow roznych od bialych) i znakow nowego wiersza.*/
ZAWARTOSC: /*pusty*/ 
| ZAWARTOSC '\n'
| ZAWARTOSC ELEMENT
| ZAWARTOSC S { 
	if(ignoruj_biale_po==0){
		if(tekst==0) {
			indent();
			tekst = 1;
		}	
		//Raczej bez sensu 
		//if(pos+strlen($2)>LINE_WIDTH) lamanie_tekstu(); 
		printf($2);
		pos+=strlen($2);
	}
} | ZAWARTOSC word { 
	if(tekst==0) {
		indent();
		tekst = 1;
	}
	if(pos+strlen($2)>LINE_WIDTH) lamanie_tekstu(); 
	printf($2);
	pos+=strlen($2);
};
	

word: CHAR | word CHAR { sprintf($$,"%s%s",$1,$2); };

%%

int main( void )
{ 
	return yyparse();
}

int yyerror( const char *txt)
{
	printf("Syntax error %s\n", txt);
	return 0;
}
void sprawdz_znaczniki(const char* z1,const char* z2)
{
	if(strcmp(z1,z2) !=0) printf("Brak dopasowania znacznikow\n");
}

void indent()
{
	for(int i=0;i<level;i++) {
		for(int j=0;j<INDENT_LENGTH;j++){
			printf(" ");
		}
	}
}
void wypisz_znaczniki(const char* z1,int typ)
{
	indent();
	if(typ == otwierajacy) printf("<%s>\n",z1);
	else if(typ == konczacy) printf("</%s>\n",z1);
	else if(typ == pusty) printf("<%s/>\n",z1);
}

void wypisz_ip(const char* ip)
{
	printf("<?%s?>\n",ip);
}

void lamanie_tekstu()
{
	printf("\n");
	indent();
	pos=INDENT_LENGTH*level;
}

