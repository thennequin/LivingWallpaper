
#include "gl\glew.h"
#include "GLShader.h"
#include <vector>

GLShader::GLShader(EType eType, const char* pShader)
{
	m_eType = eType;
	m_iShaderId = glCreateShader(eType == E_TYPE_VERTEX ? GL_VERTEX_SHADER : GL_FRAGMENT_SHADER);
	SetShader(pShader);
}

GLShader::~GLShader()
{
	glDeleteShader(m_iShaderId);
}

void GLShader::SetShader(const char* pShader)
{
	m_sShader = pShader;
	const char* pShaderStr = m_sShader.c_str();
	glShaderSource(m_iShaderId, 1, &pShaderStr, NULL);
}
bool GLShader::Compile()
{
	glCompileShader(m_iShaderId);
	
	GLint iStatus;
	glGetShaderiv(m_iShaderId, GL_COMPILE_STATUS, &iStatus);
	if (iStatus == GL_FALSE)
	{
		int iLogLength;
		glGetShaderiv(m_iShaderId, GL_INFO_LOG_LENGTH, &iLogLength);
		std::vector<char> vLog(iLogLength + 1);
		glGetShaderInfoLog(m_iShaderId, iLogLength, NULL, &vLog[0]);
		fprintf(stderr, "Error in shader compilation!\n");
		fprintf(stderr, "Info log: %s\n", &vLog[0]);
		return false;
	}
	return true;
}