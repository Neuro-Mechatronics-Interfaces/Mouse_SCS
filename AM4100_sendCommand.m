function [outstr, instr]=AM4100_sendCommand(port,instr,options)
%AM4100_SENDCOMMAND Send message to stimulator and return formatted response message.

arguments
    port (1,1) tcpclient
    instr {mustBeTextScalar}
    options.Verbose (1,1) logical = false;
end

if(port.BytesAvailable>0)
    read(port); %empties the buffer
end
write(port,uint8(sprintf('%s\r',instr)));
if options.Verbose
    fprintf('Send= %s\t\t',instr);  %display send strring
end
c=0;
while(port.BytesAvailable<1)
    c=c+1;
    pause(0.00001);
end
rplyStr=read(port,port.BytesAvailable,'char');

rplyStr=erase(rplyStr,char(13));   % remove charriage returns
rplyStr=strrep(rplyStr,newline,'~'); %replace line feeds with ~
rplyStr=strrep(rplyStr,'~~','~');
if contains(rplyStr,'*')
    rplyStr=rplyStr(1:strfind(rplyStr,'*'));
end
if(contains(rplyStr,'Bad','IgnoreCase',true) || contains(rplyStr,'?','IgnoreCase',true) )
    fprintf(2,'  %i Reply= ERROR: %s \n', c,rplyStr);  %display reply
else
    if options.Verbose
        fprintf('  %i Reply= %s \n', c,rplyStr);  %display reply
    end
end
outstr=rplyStr;
end