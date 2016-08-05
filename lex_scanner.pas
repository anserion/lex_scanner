//Copyright 2016 Andrey S. Ionisyan (anserion@gmail.com)
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

// last version: https://github.com/anserion/lex_scanner.git

{Поиск многосимвольных идентификаторов, чисел,             }
{односимвольных и двухсимвольных операций во входном потоке}
program lex_scanner(input, oufput);

const txmax = 100; {длина таблицы имен}

type
t_object = (nul,num,ident,oper);

t_sym=record 
    kind:t_object; {тип идентификатора}
    tag:integer;   {вспомогательный элемент число-метка (зарезервировано)}
    i_name:integer;  {числовое имя-код идентификатора для быстрой обработки}
    s_name:string;   {строковое имя идентификатора}
end;

const digits=['0'..'9'];
      eng_letters=['A'..'Z','a'..'z'];
      spec_letters=[',',';','!','%','?','#','$','@','&','^',
                    '/','\','|','=','<','>','(',')','{','}',
                    '[',']','+','-','*','.','''','"','`',':','~'];
//      rus_letters=['А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й'];,
//                   'К','Л','М','Н','О','П','Р','С','Т','У','Ф',
//                   'Х','Ц','Ч','Ш','Щ','Ы','Ь','Ъ','Э','Ю','Я',
//                   'а','б','в','г','д','е','ё','ж','з','и','й',
//                   'к','л','м','н','о','п','р','с','т','у','ф',
//                   'х','ц','ч','ш','щ','ы','ь','ъ','э','ю','я'];

var ch,ch2: char; {последний прочитанный входной символ и следующий за ним}
    start_of_file, end_of_file:boolean;
    id_table: array [0..txmax] of t_sym; {сводная таблица идентификаторов}
    tx: integer; {число идентификаторов в таблице}

{запись нового объекта (идентификатора), в таблицу}
procedure add_id_to_table(new_id:t_sym);
begin
    if tx<txmax then
    begin
        tx:=tx+1;
        id_table[tx]:=new_id;
    end;
end {enter};

{поиск имени id в таблице объектов-идентификаторов}
function find_by_sname(id:string): integer;
var i,res: integer;
begin
  res:=0;
  for i:=1 to tx do
    if id_table[i].s_name=id then res:=i;
  find_by_sname:=res;
end {find_by_sname};

function find_by_iname(id:integer): integer;
var i,res: integer;
begin
  res:=0;
  for i:=1 to tx do
    if id_table[i].i_name=id then res:=i;
  find_by_iname:=res;
end {find_by_iname};

{прочитать из потока ввода два символа и поместить их в ch, ch2}
procedure getch;
begin
  if end_of_file then begin write('UNEXPECTED END OF FILE'); halt(-1); end;
  if eof(input) then end_of_file:=true;
  if start_of_file then begin ch:=' '; ch2:=' '; end;
  if end_of_file then begin ch:=ch2; ch2:=' '; end;

  if not(end_of_file) and not(start_of_file) then
  begin ch:=ch2; read(ch2); end;

  if not(end_of_file) and start_of_file then
  begin
     read(ch); start_of_file:=false;
     if not(eof(input)) then read(ch2) else ch2:=' ';
  end;
end {getch};

{найти во входном потоке терминальный символ}
function getsym:t_sym;
var id: t_sym;
begin {getsym}
  {пропускаем возможные пробелы и концы строк}
  while (ch=' ')or(ch=chr(10))or(ch=chr(13)) do getch;

  id.s_name:='';
  id.kind:=nul;

  {если ch - буква или знак подчеркивния, то это - начало имени}
  if ch in ['_']+eng_letters then
  begin
    id.kind:=ident;
    {читаем посимвольно имя id[], состоящее из букв A-Z, цифр, подчеркивания}
    repeat
      id.s_name:=id.s_name+ch;
      getch;
    until not(ch in ['_']+eng_letters+digits);
  end
    else
  if ch in digits then {если ch - цифра, то это - начало числа}
  begin
    id.kind:=num;
    repeat
      id.s_name:=id.s_name+ch;
      getch;
    until not(ch in digits);
    if (ch='.')and(ch2 in digits) then
    begin
      id.s_name:=id.s_name+ch;
      getch;
      repeat
        id.s_name:=id.s_name+ch;
        getch;
      until not(ch in digits);
    end;
  end
    else
  if ch in spec_letters then
  begin {односимвольный и некоторые двусимвольные идентификаторы}
    id.kind:=oper;
    {односимвольные спецсимволы}
    id.s_name:=ch;
    {разбор случаев двусимвольных спецкомбинаций}
    if (ch='-')and(ch2='>') then begin id.s_name:='->'; getch; end;
    if (ch='<')and(ch2='-') then begin id.s_name:='<-'; getch; end;
    if (ch='<')and(ch2='>') then begin id.s_name:='<>'; getch; end;
    if (ch='!')and(ch2='=') then begin id.s_name:='!='; getch; end;
    if (ch='=')and(ch2='=') then begin id.s_name:='=='; getch; end;
    if (ch=':')and(ch2='=') then begin id.s_name:=':='; getch; end;
    if (ch='<')and(ch2='=') then begin id.s_name:='<='; getch; end;
    if (ch='>')and(ch2='=') then begin id.s_name:='>='; getch; end;
    if (ch='(')and(ch2='*') then begin id.s_name:='(*'; getch; end;
    if (ch='*')and(ch2=')') then begin id.s_name:='*)'; getch; end;
    if (ch='+')and(ch2='+') then begin id.s_name:='++'; getch; end;
    if (ch='-')and(ch2='-') then begin id.s_name:='--'; getch; end;
    if (ch='*')and(ch2='*') then begin id.s_name:='**'; getch; end;
    if (ch='.')and(ch2='.') then begin id.s_name:='..'; getch; end;
    if (ch=':')and(ch2=':') then begin id.s_name:='::'; getch; end;
    if (ch='/')and(ch2='/') then begin id.s_name:='//'; getch; end;
    if (ch='|')and(ch2='|') then begin id.s_name:='||'; getch; end;
    if (ch='&')and(ch2='&') then begin id.s_name:='&&'; getch; end;
    if (ch='^')and(ch2='^') then begin id.s_name:='^^'; getch; end;

    getch;
  end
    else
  begin
    id.s_name:=ch;
    id.kind:=nul;
    getch;
  end;
  getsym:=id;
end {getsym};

var id:t_sym; i:integer;
begin {основная программа}
start_of_file:=true; end_of_file:=false; tx:=0; 

getch;
repeat
    id:=getsym;
    add_id_to_table(id);
until id.s_name='.';

for i:=1 to tx do
  writeln(i,': symbol=',id_table[i].s_name,', kind=',id_table[i].kind);
end.
