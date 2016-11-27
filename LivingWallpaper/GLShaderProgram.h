
#ifndef __GL_SHADER_PROGRAM_H__
#define __GL_SHADER_PROGRAM_H__

#include "GLShader.h"

class GLShaderProgram
{
public:
	GLShaderProgram(GLShader* pVertex, GLShader* pFragment);
	~GLShaderProgram();

	bool Compile();
	void Use();

	bool SetFloat(const char* pName, float fValue);
	bool SetVec2(const char* pName, float fX, float fY);
	bool SetVec3(const char* pName, float fX, float fY, float fZ);
protected:
	GLShader*	m_pVertex;
	GLShader*	m_pFragment;

	GLuint		m_iProgramId;
};

#endif // __GL_SHADER_PROGRAM_H__