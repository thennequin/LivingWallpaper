
#include "gl\glew.h"
#include "GLShaderProgram.h"
#include <vector>

GLShaderProgram::GLShaderProgram(GLShader* pVertex, GLShader* pFragment)
{
	m_iProgramId = glCreateProgram();
	m_pVertex = pVertex;
	m_pFragment = pFragment;
}

GLShaderProgram::~GLShaderProgram()
{
	glDetachShader(m_iProgramId, m_pVertex->GetShaderId());
	glDetachShader(m_iProgramId, m_pFragment->GetShaderId());
	glDeleteProgram(m_iProgramId);
}

bool GLShaderProgram::Compile()
{
	glAttachShader(m_iProgramId, m_pVertex->GetShaderId());
	glAttachShader(m_iProgramId, m_pFragment->GetShaderId());
	glLinkProgram(m_iProgramId);

	GLint iStatus;
	glGetProgramiv(m_iProgramId, GL_LINK_STATUS, &iStatus);
	if (iStatus == GL_FALSE)
	{
		int iLogLength;
		glGetProgramiv(m_iProgramId, GL_INFO_LOG_LENGTH, &iLogLength);
		std::vector<char> vLog(iLogLength + 1);
		glGetProgramInfoLog(m_iProgramId, iLogLength, NULL, &vLog[0]);
		fprintf(stderr, "Error in program compilation!\n");
		fprintf(stderr, "Info log: %s\n", &vLog[0]);
		return false;
	}
	return true;
}

void GLShaderProgram::Use()
{
	glUseProgram(m_iProgramId);
}

bool GLShaderProgram::SetFloat(const char* pName, float fValue)
{
	GLint iLoc = glGetUniformLocation(m_iProgramId, pName);
	if (iLoc != -1)
	{
		glUniform1f(iLoc, fValue);
		return true;
	}
	return false;
}

bool GLShaderProgram::SetVec2(const char* pName, float fX, float fY)
{
	GLint iLoc = glGetUniformLocation(m_iProgramId, pName);
	if (iLoc != -1)
	{
		glUniform2f(iLoc, fX, fY);
		return true;
	}
	return false;
}

bool GLShaderProgram::SetVec3(const char* pName, float fX, float fY, float fZ)
{
	GLint iLoc = glGetUniformLocation(m_iProgramId, pName);
	if (iLoc != -1)
	{
		glUniform3f(iLoc, fX, fY, fZ);
		return true;
	}
	return false;
}